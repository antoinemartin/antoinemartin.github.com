---
title: Avoid Thread Issues While Testing an Android Service
date: 2012-11-08
slug: 2012/11/08/avoid-thread-issues-while-testing-an-android-service
Categories: ["Development", "Android", "Test"]
tags:
  - old
  - obsolete
  - android
  - test
  - development
---

The
[Android Test Framework](http://developer.android.com/tools/testing/testing_android.html)
provides many tools to test parts of an Android application, and the
[ServiceTestCase](http://developer.android.com/reference/android/test/ServiceTestCase.html)
in particular to test your
[Service](http://developer.android.com/reference/android/app/Service.html)
classes.

This class is quite useful but you may find yourself scratching your head
because your test does not work like it should. This happens in particular if
you're doing some background work in your service, relying for example on
[AsyncTask](http://developer.android.com/reference/android/os/AsyncTask.html)
for it.

Read on if you want to understand why it doesn't work and find a solution for
it.

<!--more-->

In an Android application, any service is instantiated and operates on the main
thread. But this is not the case in the test framework provided by the
`ServiceTestCase` class. Your Service is instantiated in the same thread the
test runs.

While your tests are running, there is no
[Looper](http://developer.android.com/reference/android/os/Looper.html) waiting
for messages on the service thread. In consequence, anything that relies on it
and on the
[Handler](http://developer.android.com/reference/android/os/Handler.html) class
to communicate back to the main thread will not work.

For instance, `AsyncTask` uses a handler to ensure that the `onPostExecute`
method is called on the main thread. After `doInBackground` has been called, it
posts a message on this handler, but as the `Looper` on the service is not
running to handle the message, the `onPostExecute` method will never be called.

To circumvent this behaviour, the service must be run on a separate thread with
a `Looper` running.

## Simulating _main thread_ behaviour

The `ThreadServiceTestCase<T extends Service>`
([source here](/downloads/code/ThreadServiceTestCase.java)) class that we
describe here provides such features. It declares a `Looper` and a `Hanlder` to
be able to run code on it:

```java
  protected Handler serviceHandler;
  protected Looper serviceLooper;
```

In the setup of the test, we instantiate the service thread, start it, and link
our handler with its looper:

```java
    @Override
    protected void setUp() throws Exception {
        super.setUp();
        // Setup service thread
        HandlerThread serviceThread = new HandlerThread("[" + serviceClass.getSimpleName() + "Thread]");
        serviceThread.start();
        serviceLooper = serviceThread.getLooper();
        serviceHandler = new Handler(serviceLooper);
    }
```

The corresponding `tearDown` method shuts down the tread.

We provide a `runOnServiceThread` method to be able to run code on the service
thread:

```java

    protected void runOnServiceThread(final Runnable r) {
        final CountDownLatch serviceSignal = new CountDownLatch(1);
        serviceHandler.post(new Runnable() {

            @Override
            public void run() {
                r.run();
                serviceSignal.countDown();
            }
        });

        try {
            serviceSignal.await();
        } catch (InterruptedException ie) {
            fail("The Service thread has been interrupted");
        }
    }
```

Then, the `startService` methods starts the service in its own thread:

```java
    static class Holder<H> {
        H value;
    }

    protected T startService(final boolean bound, final ServiceRunnable r) {
        final Holder<T> serviceHolder = new Holder<T>();

        // I want to create my service in its own 'Main thread'
        // So it can use its handler
        runOnServiceThread(new Runnable() {

            @Override
            public void run() {
                T service = null;
                if (bound) {
                    /* IBinder binder = */bindService(new Intent(getContext(), serviceClass));
                } else {
                    startService(new Intent(getContext(), serviceClass));
                }
                service = getService();
                if (r != null)
                    r.run(service);
                serviceHolder.value = service;
            }
        });

        return serviceHolder.value;
    }
```

The `bound` parameters tells wether to start the service with a binding or with
an `Intent`.. The optional `ServiceRunnable` parameter can be provided to add
some initialization code.

A test class using this code looks like the following:

```java
public class MyServiceTest extends ThreadServiceTestCase<MyService> {

    public MyServiceTest() {
        super(MyService.class);
    }


    public void testSomething() {

        // starts the service
        MyService service = startService(true, null);
        ...
        // Do something on the service
        runOnServiceThread( new ServiceRunnable() {
            public void run(Service service) {
                // do something
            }
        });

    }
```

With it, the service is started in its own thread and the `Looper` and `Handler`
mechanism will work.

## Waiting for listeners to be notified

A service that performs tasks asynchronously also notifies the outcome of the
background tasks asynchronously. There are several techniques for doing that,
but the most common are :

- Broadcast an intent, or
- Call a callback method on listeners.

This usually happens in the main thread. In our case, it would happen in the
service thread. As the test is executing itself in its own thread, some
synchronization mechanism is needed between the service thread and the test
thread to be able to handle the outcome of the background task in the test.

The `ThreadServiceTestCase` class provides an helper class for that:

```java
    public static class ServiceSyncHelper {
        // The semaphore will wakeup clients
        protected final Semaphore semaphore = new Semaphore(0);

        /**
         * Waits for some response coming from the service.
         *
         * @param timeout
         *            The maximum time to wait.
         * @throws InterruptedException
         *             if the Thread is interrupted or reaches the timeout.
         */
        public synchronized void waitListener(long timeout) throws InterruptedException {
            if (!semaphore.tryAcquire(timeout, TimeUnit.MILLISECONDS))
                throw new InterruptedException();
        }

    }
```

It contains a semaphore that can be used to synchronize the service thread with
the test thread.

In the case of the callback listener, we can then define an utility class like
the following:

```java
    static class SynchronizedListener extends ServiceSyncHelper {
        Object result;

        /**
         * Service listener that registers the value returned by the service in
         * the holder and release the semaphore.
         */
        final MyService.Listener listener = new MyService.Listener() {
            public void onTaskPerformed(MyService service, Object returnValue) {
                result = returnValue;
                semaphore.release();
            }
        };

    }

```

When notified by the service in the service thread, the contained listener
releases the semaphore and awakes the test that is waiting on the semaphore.

The listener contained in the helper class also needs to be added to the service
being tested at service initialization. A test using this feature then becomes :

```java
public void testSomething() {

    // Catch listener callback in the test
    final SynchronizedListener listener = new SynchronizedListener();

    // starts the service
    /* MyService service = */ startService(true, new ServiceRunnable() {
        @Override
        public void run(Service service) {
        // add our listener to the service
            service.addListener(listener);
        }
    });

    // wait for the service to notify us
    try {
        // Wait for the service to perform its background task
        listener.waitListener(WAIT_TIME);
    } catch (InterruptedException ie) {
        fail("The listener never got signaled");
    }

    assertEquals(expected_value, listener.result );
    ...
}
```

You can grab The `ThreadServiceTestCase<T extends Service>` source code
[here](/downloads/code/ThreadServiceTestCase.java). Hope it will help.

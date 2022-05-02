---
title: "Checking Google Play Signatures on .Net"
date: "2012-11-15"
slug: "2012/11/15/checking-google-play-signatures-on-net"
Categories: ["Development", "Android"]
tags: [old, android, "google play", ".net"]
---

With
[In-App Billing](http://developer.android.com/guide/google/play/billing/billing_integrate.html)
on Android, each time a purchase occurs, your application receives a JSON
payload containing information about the purchase, as well as its signature with
your developer certificate.

Google encourages you to verify that the signature is valid to authentify the
purchase. You can do that inside the application, but if the delivery of the
purchase involves a server, it is better to do it on the server to prevent
client code manipulation. The following show how to do it on .Net server
application.

<!-- More -->

The JSON payload looks like the following :

```js
{ "nonce" : 1836535032137741465,
  "orders" :
    [{ "notificationId" : "android.test.purchased",
       "orderId" : "transactionId.android.test.purchased",
       "packageName" : "com.example.dungeons",
       "productId" : "android.test.purchased",
       "developerPayload" : "bGoa+V7g/yqDXvKRqq+JTFn4uQZbPiQJo4pf9RzJ",
       "purchaseTime" : 1290114783411,
       "purchaseState" : 0,
       "purchaseToken" : "rojeslcdyyiapnqcynkjyyjh" }]
}
```

You receive it with a broadcast
`com.android.vending.billing.PURCHASE_STATE_CHANGED` in the `inapp_signed_data`
extra intent field. The signature comes as a base 64 encoded string in the
`inapp_signature` intent field and looks like this :

```text
YlNBaqlKSS+zk/fteJuHbvI3/N+hbiLiolYsMl8gCD13+Ii+1m4GSd68rc2TwbSLYsYrHVL/9xg/0CBf
CN6NKLtqjFqRs034ExCW2qaMddwfRiqsGZ3z7ZvWuMyNntE3pTGTxG2X/71/cpGwQoSFQBceVR9t5Sge
Tw5HJimt5xlIhHqgRxS/W/kfrJIyKt03l2hUJDGOX9eig5S4ex6fgyFZxR73/HxOFGJ9ohApwaBNF7rD
LaMZFnYbLsYgBWMOHW1uE+F5b2JZWvyColpe5SKMWaNVWVWZGte1WBOYRFxbriZR1VwClkEg9Y4mVn5k
SZIje5pSueLKwiForU02jA==
```

It is the signature of the `SHA1` digest of the JSON payload with the private
key of your developer certificate. Don't look for this private key, it is
detained by Google. Google only provides you the corresponding public key in the
profile page of your developer account :

![Billing public key](http://i.stack.imgur.com/X78qs.png)

This public key is the base 64 string of the
[Subject Public Key Info](http://tools.ietf.org/html/rfc3280#section-4.1.2.7) of
your certificate encoded in the
[DER format](http://en.wikipedia.org/wiki/Distinguished_Encoding_Rules#DER_encoding).
It corresponds to the following part of your certificate:

```text
Certificate:
...
       Subject Public Key Info:
           Public Key Algorithm: rsaEncryption
           RSA Public Key: (1024 bit)
               Modulus (1024 bit):
                   00:b4:31:98:0a:c4:bc:62:c1:88:aa:dc:b0:c8:bb:
                   33:35:19:d5:0c:64:b9:3d:41:b2:96:fc:f3:31:e1:
                   66:36:d0:8e:56:12:44:ba:75:eb:e8:1c:9c:5b:66:
                   70:33:52:14:c9:ec:4f:91:51:70:39:de:53:85:17:
                   16:94:6e:ee:f4:d5:6f:d5:ca:b3:47:5e:1b:0c:7b:
                   c5:cc:2b:6b:c1:90:c3:16:31:0d:bf:7a:c7:47:77:
                   8f:a0:21:c7:4c:d0:16:65:00:c1:0f:d7:b8:80:e3:
                   d2:75:6b:c1:ea:9e:5c:5c:ea:7d:c1:a1:10:bc:b8:
                   e8:35:1c:9e:27:52:7e:41:8f
               Exponent: 65537 (0x10001)
...
```

The public key in this format cannot be read directly by the
`RSACryptoServiceProvider` class of the .Net `System.Security.Cryptography`
module. The preferred import format for this class is XML. The
[Bouncy Castle Library](http://www.bouncycastle.org/) allows reading this kind
of encoding, but you don't really need to add a new dependency to your project.
Instead, what you need is simply to convert your public key in XML. Once this is
done, you can use the following simple .Net code to check the signature:

```csharp
        public static bool verify(String message, String base64Signature, String publicKey)
        {
            // By default the result is false
            bool result = false;
            try
            {
                // Create the provider and load the KEY
                RSACryptoServiceProvider provider = new RSACryptoServiceProvider();
                provider.FromXmlString(publicKey);

                // The signature is supposed to be encoded in base64 and the SHA1 checksum
                // Of the message is computed against the UTF-8 representation of the
                // message
                byte[] signature = Convert.FromBase64String(base64Signature);
                SHA1Managed sha = new SHA1Managed();
                byte[] data = Encoding.UTF8.GetBytes(message);

                result = provider.VerifyData(data, sha, signature);
            }
            catch (Exception /* e */) { /* TODO: add some kind of logging here */}
            return result;
        }
```

For converting your key, you can download the
[PEMKeyLoader class](/downloads/code/PEMKeyLoader.cs) and use it in a Console
Project to convert your key to XML with the follwing code :

```csharp
...

RSACryptoServiceProvider provider = PEMKeyLoader.CryptoServiceProviderFromPublicKeyInfo(MY_BASE64_PUBLIC_KEY);
Console.WriteLine(provider.ToXmlString(false));
...

```

You will obtain your XML formatted key :

```xml
<RSAKeyValue><Modulus>u5xfVod+5uEP7Zu/xN3v4yhAO3tSsezDJUBajr92u+wUXZNH2IKt/9/V/HjMyzW5AC0PZpi6ROTWvQoO5Xa2L8+lKLiVtVcaI60O+M6B1Rn1zCYD//TgYwfqofKPvbv/Vshl+LwdkqBcp1as4t6+2f0sGHwH/hT1D+E94m0zf4qOR5O5o3ILXaC1z8pAoV4cM6YttFRDh9lxPj/9hkQR4l809bbxOdJPo41F69rqdyU4xFjncxCOHcFdnkT7LQUVv1v2GYae3Rl4iZVncbEygg4K/+uG21QyC0xRda9L2KmQyV7Mtcb5YTJzyfaI/Z/EEZ0A2pkX+4Ki1MKCaUAPLw==</Modulus><Exponent>AQAC</Exponent></RSAKeyValue>
```

That you can use then in your project as a string constant.

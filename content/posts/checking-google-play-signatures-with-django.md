---
title: 'Checking Google Play Signatures With Django'
date: '2012-03-12'
slug: '2012/03/12/checking-google-play-signatures-with-django'
Categories: ['Development', 'Django', 'Android']
tags:
    - old
    - android
    - django
    - android
    - security
---

Google play, formerly known as the Android Market, provides in-app billing in
several countries. In the
[Security and Design](http://developer.android.com/guide/market/billing/billing_best_practices.html)
page, Google states the following:

> If practical, you should perform signature verification on a remote server and
> not on a device. Implementing the verification process on a server makes it
> difficult for attackers to break the verification process by reverse
> engineering your .apk file. If you do offload security processing to a remote
> server, be sure that the device-server handshake is secure.

The signature verification here refers to the signature sent back by the Billing
Service to the `GET_PURCHASE_INFORMATION`request. The signature is against the
JSON payload containing the purchase information. We'llget back later on the
authentication of the dialog with the server.

<!-- more -->

The JSON payload looks like the following (It has been indented for
readability):

```js
{
  "nonce":7822246098812800204,
  "orders":[
    {
      "notificationId":"-915368186294557970",
      "orderId":"971056902421676",
      "packageName":"com.xxx.yyy",
      "productId":"com.xxx.yyy.product",
      "purchaseTime":1331562686000,
      "purchaseState":1,
      "developerPayload":"WEHJSU"
    }
  ]
}
```

And we we receive a signature in `Base64`:

```text
rKf9B38gLbJaLiyRbQVJNr0i0IvJxBgi3EmsLoZLkFedZvn642s4+fz3jYCk6IVWWFSqtBH2Z8ChONJkHWrkDUCK79uSBPLN5s4x4AsRHgQ8aw3sRQLAoEDMFA1ym1gkfYfDz+6sxP2Rgg1U/qpHIEHWPDbJAdP7zcM1iz2kEWbYvFwKP3NNWExNB4gWH3IFtPR0l/KLjKBoqpX5zVukmUeaZW0Skx10eFROa4VhqA5JrbZZQwK0jc6FCYi3u6c1ryIw6W5tcdIv1PFOKpE7VMq67yyD+IEXc+nl29FN5ByGhkj/khNY1KLXcszCCa7ygSYw7mQI+omLdyMz6aL3hg==

```

The payload is signed with the Private key associated with you Google Play
account. You can grab your public key in
[your developer console page](https://play.google.com/apps/publish/Home#ProfileEditorPlace:).

There are several crypto solutions available in python. In our example, we use
[pycrypto](https://www.dlitz.net/software/pycrypto/). It can easily be installed
in your Django virtual environment with:

```console
> pip install pycrypto
```

Then, the following method allows checking of the payload signature:

```python

from Crypto.Signature import PKCS1_v1_5
from Crypto.Hash import SHA
from Crypto.PublicKey import RSA
import base64

PUBLIC_KEY='<Put here your public key>'
VERIFY_KEY= RSA.importKey(base64.decodestring(PUBLIC_KEY))

def verify_signature(message, signature):
    '''Verify that signature is the result of signing message'''
    # Get the hash of the message
    h = SHA.new(message)
    # Create a verifier
    verifier = PKCS1_v1_5.new(VERIFY_KEY)
    # decode the signature
    signature = base64.decodestring(signature)
    # verify
    return verifier.verify(h, signature)
```

In a next post, we'll se how to make sure on the Android application side that
the responses to our requests are really coming from our server.

# Step 4: FastAPI skeleton with JSON logs and non-root multi-stage image

## What does `--require-hashes` protect against?

This option protects against the OWASP risk LLM03: Supply Chain. If the hash of the downloaded package does not match the hash recorded for that version in `requirements.txt`, the installation stops.

## Why do we build in two stages?

We build the application in two stages. Stage one is the builder: we install the compiler toolchain to build the dependencies and the application. In stage two, we start from a new base image and copy only the result of the build. This avoids many vulnerabilities and reduces the size of the image. For the moment, build tools such as pip are still in the image, but in step 8 (hardening), we will also remove them. This makes it harder for attackers to install or build their own tools.

## Why never log the headers and body of requests?

Because the headers and body contain sensitive and secret information, such as PII and the API key. This protects against the OWASP risk LLM02: Sensitive Information Disclosure.

## Why disable `/docs`?

`/docs` contains the map of the API. This information is a risk: if attackers know the map of the API, they know how to attack it.

## Why is the code owned by root while the application runs as user 10002?

The code is owned by root to protect it against modification. If someone gains access to the application process, they cannot modify the code because they do not have the rights. The API can only read the code, not modify it.

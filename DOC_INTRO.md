# API Documentation

## Authentication

To authenticate user an `Authorization` header with a token value must be passed in every request to the API like this:
```
authorization: Bearer 7dWR/dflC1F31NCrsavT
```

In case the token value is invalid a `403 Forbidden` with text `invalid token` will be returned in response *kept for compatibility, should be replaced with unified JSON response*.

In case the user can't be authenticated with the provided token (e.g. he is banned) the following JSON response is returned with `403 Forbidden` status code:
```json
{"success": false, "error": "banned", "reason": "This user account was banned"}
```

# HYWORK API testing status

Last updated: **2026-11-17 (Asia/Karachi)**.

These findings record the latest **user-reported Postman testing results**. The requests were not rerun as part of this documentation update. Exact HTTP status codes are included only where supplied. This report does not establish that each tested operation is integrated into the Flutter app.

Base URL: `http://35.154.187.106/api`

Public mobile API reference: [OpenAPI specification](http://35.154.187.106/api/docs/openapi-user.json).

## Working

| Endpoint | HTTP method | Test result | Remaining issue or verification boundary |
| --- | --- | --- | --- |
| `/auth/request-otp` → `/auth/verify-otp` | POST for both steps | Email OTP login completed and an authentication token was generated. | Reported as a successful flow; separate HTTP status codes for its steps were not supplied. |
| `/auth/me` | GET | Current user retrieval worked with `Authorization: Bearer <token>`. | This confirms authenticated retrieval, not that every profile field can be edited. |
| `/users/me` | PATCH | Returned **200 OK**. Profile fields `name`, `username`, `bio`, `city` and `gender` were returned successfully. | A 200 response does not confirm persistence of every submitted field. See Partially Verified below. |
| `/users/me` | PATCH | City update was confirmed saved as **Islamabad**. | This persistence result applies to `city`; it must not be generalized to other fields. |

No actual authentication tokens are recorded in this document.

## Partially Verified

| Endpoint | HTTP method | Field or operation | Test result | Remaining issue |
| --- | --- | --- | --- | --- |
| `/users/me` | PATCH | `name`, `username`, `bio`, `gender` | These fields were returned successfully in the 200 OK response. | Independent change-and-reload persistence for each field was not separately reported. |
| `/auth/me` / `/users/me` | GET / PATCH | `email` | Email was returned correctly in the tested profile data. | Changing the email and subsequently retrieving the changed value is **not yet verified**. Returning an email does not establish support for editing it. |
| `/users/me` | PATCH | `nationality` | Included in the PATCH request, but missing from the response. | Persistence is **not confirmed**. Do not describe this field as saved or accepted solely because the request returned 200. |
| `/users/me` | PATCH | `businessType` | Included in the PATCH request, but missing from the response. | Persistence is **not confirmed**. The result does not establish whether the field was ignored, stored without being returned, or otherwise unsupported. |
| `/users/me` | PATCH | `avatarUrl` | Supported in the documented PATCH request schema. | Actual image uploading is not working. A successful new-image upload, avatar URL update and subsequent retrieval have not been verified. Schema support alone does not establish a working image-upload flow. |

## Blocked

| Endpoint | HTTP method | Test result | Remaining issue |
| --- | --- | --- | --- |
| `http://35.154.187.106/api/uploads` | POST | Tested in Postman and returned **404 Not Found**. | The upload request did not succeed at this tested URL and method. The correct deployed upload contract and the cause of the 404 require clarification. |
| `/uploads` → `/users/me` | POST → PATCH | End-to-end profile image upload is **not working**. | A working upload must first return an image URL that can be saved through `avatarUrl`. This sequence has not been verified successfully. |

The upload finding is specifically a **POST** result; it is not inferred from a GET request. The 404 alone does not determine whether the cause is a missing route, an incorrect deployment path or outdated documentation.

## Remaining verification

- Confirm the supported email-change workflow, then test saving and retrieving a changed email with an authorized test account.
- Confirm the exact request/response contract for `nationality` and `businessType`, then verify each field through a subsequent profile retrieval. Their presence in a request is insufficient proof of persistence.
- Resolve the POST `/uploads` 404 and confirm the upload URL, HTTP method, request format, file-field name and response containing the usable image URL.
- Once uploading works, verify upload → returned URL → PATCH `avatarUrl` → profile retrieval and image display.

No other endpoints, login methods, profile fields or error scenarios are marked working by this report.

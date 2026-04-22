---
name: dotnet-e2e-test
description: Writes a reliable end-to-end integration test for a dotnet backend project, following established patterns for database interaction, API calls, and mocking.
---

### Goal

-   Create a high-quality end-to-end integration test that verifies realistic user scenarios through public HTTP APIs and real workflow transitions.
-   Ensure tests are deterministic, stable, and readable.

### Preconditions

-   The test class is part of an xUnit `[Collection(...)]` and uses a shared test fixture (e.g., `IntegrationTestFixture`).
-   External dependencies are stubbed through a mock server (e.g., `fixture.MockServer`).
-   Test data uses fixed IDs, dates, and payload strings to ensure deterministic runs.

### Recipe (follow in order)

1.  **Reset and Seed State:**
    -   Begin by resetting the database to a clean state (e.g., `fixture.ResetDbAsync()`).
    -   Load any necessary baseline entities for the test (e.g., `fixture.LoadCustomersAsync()`).
    -   Define constants for IDs and other expected values at the class scope.

2.  **Stub External Services:**
    -   Configure the mock server (`fixture.MockServer`) to respond to any expected outbound calls from your application.
    -   Define mock responses with the exact path, method, and JSON body that the application expects.

3.  **Inject Input:**
    -   Trigger the system under test through its real entrypoint. This could be a message queue (`fixture.MessageHelper.SendMessage(...)`) or a direct API call (`fixture.HttpClient.PostAsync(...)`).
    -   Use full, realistic JSON payloads with the stable test values defined as constants.

4.  **Wait for Asynchronous Processes:**
    -   If the action triggers an asynchronous process, use a polling mechanism like `FluentWait` to await a specific condition before making assertions.
    -   Assert the HTTP status and response body content *inside* the polling block.

5.  **Drive State Transitions (if applicable):**
    -   If the test involves multiple steps, drive state transitions through the public API (e.g., `PATCH` requests) rather than writing directly to the database.
    -   Assert the response of each transition immediately.

6.  **Trigger Background Actions (if applicable):**
    -   If the test needs to verify the outcome of a background job, run the job explicitly (e.g., `JobRunner.RunAsync(["--job", "my-job"], fixture.Services)`).

7.  **Assert Final Outcome:**
    -   Query the final state of the system through its public API (e.g., `GET V1/my-entity?...`).
    -   Assert the status code and the response body.
    -   Validate both the existence of the entity and that the business-relevant fields have been updated correctly.

### Quality Checklist

-   The test name follows the pattern `RunAsync_With<Scenario>_Should<Outcome>EndToEnd`.
-   The test uses no random values, no `DateTime.Now`, and no fixed `Task.Delay` calls.
-   Every API call checks the status code and includes the response body in the failure message where helpful.
-   Assertions validate both the existence of data and the specific field changes relevant to the business logic.
-   The mock server setup is self-contained within the test class and reflects the actual integration contract.

### Starter Template

See `examples/E2ETestStyleTemplate.cs` for a reference implementation.

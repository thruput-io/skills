// This is a template for creating new end-to-end integration tests.
// Before you start, read the SKILL.md for this skill to understand the patterns and conventions.

using System.Net;
using System.Text;
using IntegrationTests.Infrastructure;
using IntegrationTests.Util;
using Shouldly;
using WireMock.RequestBuilders;
using WireMock.ResponseBuilders;

namespace IntegrationTests;

[Collection("IntegrationTests")]
public class ExampleE2ETest(IntegrationTestFixture fixture)
{
    // --- 1. Define Constants ---
    // Use fixed, deterministic values for all IDs, names, and other test data.
    private const string EntityId = "00000000-0000-0000-0000-0000000000AA";
    private const string ExternalId = "11111111-0000-0000-0000-000000000001";

    [Fact]
    public async Task RunAsync_WithFullScenario_ShouldProduceExpectedOutcome()
    {
        // --- 2. Arrange ---
        
        // Reset the database to a known clean state.
        await fixture.ResetDbAsync();

        // Seed the database with any necessary baseline data.
        // Example: await fixture.LoadCustomersAsync();
        
        // Setup mock responses for any external services your application calls.
        SetupExternalServiceStub();

        // --- 3. Act ---
        
        // Trigger the system under test. This can be a message queue or a direct API call.
        // Example: await fixture.MessageHelper.SendMessage(BuildInputPayload(), "your-queue");
        
        // For asynchronous processes, poll for a condition before making assertions.
        await FluentWait
            .Await(TimeSpan.FromSeconds(5))
            .PollInterval(TimeSpan.FromMilliseconds(200))
            .UntilAssertedAsync(async () =>
            {
                var response = await fixture.HttpClient.GetAsync(
                    "V1/your-entity/some-query",
                    TestContext.Current.CancellationToken);

                response.StatusCode.ShouldBe(HttpStatusCode.OK);
            });
            
        // If your test involves multiple steps, drive state transitions via the API.
        // Example:
        // var transitionResponse = await fixture.HttpClient.PatchAsync(
        //     $"V1/your-entity/{EntityId}/status",
        //     new StringContent("{"status":"completed"}", Encoding.UTF8, "application/json"),
        //     TestContext.Current.CancellationToken);
        // transitionResponse.StatusCode.ShouldBe(HttpStatusCode.NoContent);

        // If your test verifies a background job, run it explicitly.
        // Example: await JobRunner.RunAsync(["--job", "your-job"], fixture.Services);
        
        // --- 4. Assert ---

        // Query the final state of the system via its public API.
        var finalResponse = await fixture.HttpClient.GetAsync(
            $"V1/your-entity/{EntityId}",
            TestContext.Current.CancellationToken);

        var finalBody = await finalResponse.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        
        // Assert the final outcome. Be specific.
        finalResponse.StatusCode.ShouldBe(HttpStatusCode.OK, finalBody);
        finalBody.ShouldContain(EntityId.ToLowerInvariant());
        // Example: finalBody.ShouldContain(""status":"archived"");
    }

    private void SetupExternalServiceStub()
    {
        fixture.MockServer
            .Given(Request.Create().WithPath($"/external-resource/{ExternalId}").UsingGet())
            .RespondWith(
                Response.Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody($"{{"id":"{ExternalId}"}}"));
    }

    private static string BuildInputPayload() =>
        $$"""
        {
          "entityId": "{{EntityId}}"
        }
        """;
}

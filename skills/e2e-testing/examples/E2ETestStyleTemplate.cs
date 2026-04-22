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
    private const string LeadId = "00000000-0000-0000-0000-0000000000AA";
    private const string ExternalId = "11111111-0000-0000-0000-000000000001";

    [Fact]
    public async Task RunAsync_WithScenario_ShouldProduceExpectedOutcomeEndToEnd()
    {
        await fixture.ResetDbAsync();
        await fixture.LoadCustomersAndDealersAsync();
        SetupExternalStub();

        await fixture.MessageHelper.SendMessage(BuildInputPayload(), "leads");

        await FluentWait
            .Await(TimeSpan.FromSeconds(5))
            .PollInterval(TimeSpan.FromMilliseconds(200))
            .UntilAssertedAsync(async () =>
            {
                var response = await fixture.HttpClient.GetAsync(
                    "V1/leads?dealerId=000000001",
                    TestContext.Current.CancellationToken);

                response.StatusCode.ShouldBe(HttpStatusCode.OK);
            });

        var transitionResponse = await fixture.HttpClient.PatchAsync(
            $"V1/leads/{LeadId}/workflow",
            new StringContent("{\"workFinishedAt\":\"2026-01-01T00:00:00Z\"}", Encoding.UTF8, "application/json"),
            TestContext.Current.CancellationToken);

        transitionResponse.StatusCode.ShouldBe(HttpStatusCode.NoContent);

        await JobRunner.RunAsync(["--job", "archive"], fixture.Services);

        var finalResponse = await fixture.HttpClient.GetAsync(
            "V1/leads?dealerId=000000001",
            TestContext.Current.CancellationToken);

        var finalBody = await finalResponse.Content.ReadAsStringAsync(TestContext.Current.CancellationToken);
        finalResponse.StatusCode.ShouldBe(HttpStatusCode.OK, finalBody);
        finalBody.ShouldContain(LeadId.ToLowerInvariant());
    }

    private void SetupExternalStub()
    {
        fixture.MockServer
            .Given(Request.Create().WithPath($"/resource/{ExternalId}").UsingGet())
            .RespondWith(
                Response.Create()
                    .WithStatusCode(200)
                    .WithHeader("Content-Type", "application/json")
                    .WithBody("{\"id\":\"11111111-0000-0000-0000-000000000001\"}"));
    }

    private static string BuildInputPayload() =>
        """
        {
          "leadId": "00000000-0000-0000-0000-0000000000AA"
        }
        """;
}

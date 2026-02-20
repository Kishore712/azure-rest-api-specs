import "../common/models.tsp";
import "./models.tsp";

using TypeSpec.Http;
using TypeSpec.OpenAPI;

namespace Azure.AI.Projects;

#suppress "@azure-tools/typespec-azure-core/use-standard-operations" ""
@tag("Invoke")
interface Invoke {
  /**
   * Invoke an agent. Supports both non-streaming and streaming (SSE) responses
   * controlled by the `stream` field in the request body.
   *
   * For non-streaming: returns an InvokeResponse with the agent's output.
   * For streaming: returns Server-Sent Events with incremental text deltas
   * and a terminal invocation.completed event.
   */
  #suppress "@azure-tools/typespec-azure-core/no-unnamed-union" ""
  @post
  @route("/invoke")
  @extension("x-ms-foundry-meta", #{ required_previews: #[FoundryFeaturesOptInKeys.hosted_agents_v1_preview] })
  invoke is FoundryDataPlanePreviewOperation<
    FoundryFeaturesOptInKeys.hosted_agents_v1_preview,
    InvokeRequest,
    InvokeResponse
  >;
}

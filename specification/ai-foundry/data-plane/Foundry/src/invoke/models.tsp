import "../common/models.tsp";

using TypeSpec.Http;
using TypeSpec.OpenAPI;

namespace Azure.AI.Projects;

// --- Enums ---

@doc("The status of an invocation.")
union InvocationStatus {
  string,

  @doc("Agent finished and produced final output.")
  completed: "completed",

  @doc("Agent paused and is waiting for human input.")
  requires_input: "requires_input",

  @doc("Agent encountered an error.")
  failed: "failed",

  @doc("Invocation was cancelled.")
  cancelled: "cancelled",
}

@doc("The type of input item.")
union InputItemType {
  string,

  @doc("Text input.")
  text: "text",

  @doc("Image input.")
  image: "image",

  @doc("Audio input.")
  audio: "audio",

  @doc("Document input.")
  document: "document",
}

@doc("The type of input source.")
union InputSourceType {
  string,

  @doc("URL reference.")
  url: "url",

  @doc("Platform-managed file.")
  file: "file",

  @doc("Inline base64-encoded data.")
  base64: "base64",
}

@doc("The type of annotation.")
union AnnotationType {
  string,

  @doc("A file annotation.")
  file: "file",
}

@doc("The type of agent.")
union AgentDefType {
  string,

  @doc("A hosted agent.")
  hosted: "hosted",

  @doc("A prompt agent.")
  prompt: "prompt",

  @doc("A workflow agent.")
  workflow: "workflow",
}

// --- Input Source (discriminated union) ---

@doc("The source of an input item.")
@discriminator("type")
model InputSource {
  @doc("The type of the input source.")
  type: InputSourceType;
}

@doc("A URL input source.")
model UrlInputSource extends InputSource {
  type: InputSourceType.url;

  @doc("The URL to fetch the input from.")
  url: string;
}

@doc("A platform-managed file input source.")
model FileInputSource extends InputSource {
  type: InputSourceType.file;

  @doc("The file ID obtained from the Files API.")
  file_id: string;
}

@doc("An inline base64-encoded input source.")
model Base64InputSource extends InputSource {
  type: InputSourceType.base64;

  @doc("The MIME type of the data for decoding.")
  media_type: string;

  @doc("The base64-encoded data.")
  data: string;
}

// --- Input Items (discriminated union) ---

@doc("An input item for an invocation.")
@discriminator("type")
model InputItem {
  @doc("The type of the input item.")
  type: InputItemType;
}

@doc("A text input item.")
model TextInputItem extends InputItem {
  type: InputItemType.text;

  @doc("The text content.")
  text: string;
}

@doc("An image input item.")
model ImageInputItem extends InputItem {
  type: InputItemType.image;

  @doc("The source of the image.")
  source: InputSource;

  @doc("The image format. Auto-detected if not provided.")
  format?: string;
}

@doc("An audio input item.")
model AudioInputItem extends InputItem {
  type: InputItemType.audio;

  @doc("The source of the audio.")
  source: InputSource;

  @doc("The audio format (e.g., pcm16, mp3, wav, opus). Default: pcm16.")
  format?: string;

  @doc("Modality-specific parameters such as sample_rate.")
  options?: Record<unknown>;
}

@doc("A document input item.")
model DocumentInputItem extends InputItem {
  type: InputItemType.document;

  @doc("The source of the document.")
  source: InputSource;

  @doc("Modality-specific parameters such as media_type.")
  options?: Record<unknown>;
}

// --- Agent Reference ---

@doc("A reference to the agent being invoked.")
model AgentDef {
  @doc("The name of the agent.")
  name: string;

  @doc("The version of the agent (e.g., \"1.0\").")
  version: string;

  @doc("The type of the agent.")
  type: AgentDefType;
}

// --- Resume (Human-in-the-loop) ---

@doc("A resume request used when responding to an interrupt.")
model ResumeRequest {
  @doc("Must match the interrupt's id that is being responded to.")
  interrupt_id: string;

  @doc("The human's response. Can be a simple string or structured JSON.")
  value: unknown;
}

// --- Annotations ---

@doc("An annotation attached to an invocation response.")
@discriminator("type")
model Annotation {
  @doc("The annotation type.")
  type: AnnotationType;
}

@doc("A file annotation produced by the agent.")
model FileAnnotation extends Annotation {
  type: AnnotationType.file;

  @doc("The platform-managed file ID.")
  file_id: string;

  @doc("The filename of the produced file.")
  filename: string;

  @doc("The MIME type of the file.")
  mime_type: string;

  @doc("The size of the file in bytes.")
  size_bytes: int64;
}

// --- Interrupt ---

@doc("Information about a human-in-the-loop interrupt.")
model InterruptInfo {
  @doc("Unique identifier for this interrupt. Must be sent back in the resume request.")
  id: string;

  @doc("Human-readable description of the input needed.")
  message: string;
}

// --- Error ---

@doc("Error information for a failed invocation.")
model InvokeError {
  @doc("Machine-readable error code.")
  code: string;

  @doc("Human-readable error message.")
  message: string;
}

// --- Request ---

@doc("Request body for invoking an agent.")
@extension("x-ms-foundry-meta", #{ required_previews: #[FoundryFeaturesOptInKeys.hosted_agents_v1_preview] })
model InvokeRequest {
  @doc("Agent reference identifying which agent to invoke.")
  agent_def: AgentDef;

  @doc("""
    Array of input items (text, images, audio, documents). Required when resume is not present.
    Mutually exclusive with resume.
    """)
  input?: InputItem[];

  @doc("Identifier of an existing session. Omit to create a new one.")
  session_id?: string;

  @doc("Optional identifier for grouping related invocations into a logical conversation.")
  conversation_id?: string;

  @doc("When true, response is delivered as Server-Sent Events. Default false.")
  stream?: boolean;

  @doc("""
    Opaque JSON object forwarded to the agent container as-is.
    Use for model-level knobs (temperature, max_tokens), custom agent flags, or runtime configuration.
    AgentService does not parse or validate this.
    """)
  agent_payload?: Record<unknown>;

  @doc("""
    Used when responding to an interrupt (status == requires_input).
    Mutually exclusive with input.
    """)
  resume?: ResumeRequest;

  @doc("Key-value pairs stored by AgentService for tracing, auditing, and correlation.")
  metadata?: Record<string>;
}

// --- Response ---

@doc("Response from invoking an agent.")
model InvokeResponse {
  @doc("Unique identifier for this invocation.")
  id: string;

  @doc("Terminal state of the invocation.")
  status: InvocationStatus;

  @doc("Session this invocation belongs to. Store and send in subsequent requests for multi-turn.")
  session_id: string;

  @doc("Conversation ID if provided in the request. Echoed back for correlation.")
  conversation_id?: string;

  @doc("The agent's text response.")
  message: string;

  @doc("Array of annotations (file references, citations) attached to the response. Empty when text-only.")
  annotations: Annotation[];

  @doc("Non-null when status is requires_input. Contains interrupt ID and message.")
  interrupt?: InterruptInfo;

  @doc("Non-null when status is failed. Contains error code and message.")
  error?: InvokeError;

  @doc("Unix timestamp (seconds) when invocation started.")
  @encode("unixTimestamp", int32)
  created_at: utcDateTime;

  @doc("Unix timestamp (seconds) when invocation completed. Null when paused.")
  @encode("unixTimestamp", int32)
  completed_at?: utcDateTime;
}

// --- Streaming Events ---

@doc("SSE event types for streaming invocations.")
union InvokeStreamEventType {
  string,

  @doc("Invocation started.")
  invocation_created: "invocation.created",

  @doc("Incremental text chunk from the agent.")
  message_delta: "message.delta",

  @doc("A file annotation.")
  annotation: "annotation",

  @doc("Agent paused for human input.")
  interrupt: "interrupt",

  @doc("Terminal event with full response.")
  invocation_completed: "invocation.completed",

  @doc("Stream-level error.")
  error: "error",
}

@doc("A streaming event from an invocation.")
@discriminator("type")
model InvokeStreamEvent {
  @doc("The event type.")
  type: InvokeStreamEventType;
}

@doc("Invocation started event.")
model InvocationCreatedEvent extends InvokeStreamEvent {
  type: InvokeStreamEventType.invocation_created;

  @doc("The invocation ID.")
  id: string;

  @doc("The session ID.")
  session_id: string;

  @doc("The conversation ID if provided.")
  conversation_id?: string;

  @doc("Status is always in_progress.")
  status: "in_progress";
}

@doc("Incremental text chunk from the agent.")
model MessageDeltaEvent extends InvokeStreamEvent {
  type: InvokeStreamEventType.message_delta;

  @doc("Sequence number starting at 1, incrementing with each delta.")
  sequence_number: int32;

  @doc("The text chunk.")
  delta: string;
}

@doc("An annotation event.")
model AnnotationEvent extends InvokeStreamEvent {
  type: InvokeStreamEventType.annotation;

  @doc("The annotation data.")
  annotation: Annotation;
}

@doc("An interrupt event for human-in-the-loop.")
model InterruptEvent extends InvokeStreamEvent {
  type: InvokeStreamEventType.interrupt;

  @doc("The interrupt information.")
  interrupt: InterruptInfo;
}

@doc("Terminal event containing the full response.")
model InvocationCompletedEvent extends InvokeStreamEvent {
  type: InvokeStreamEventType.invocation_completed;

  @doc("The full invocation response.")
  response: InvokeResponse;
}

@doc("Stream-level error event.")
model InvokeErrorEvent extends InvokeStreamEvent {
  type: InvokeStreamEventType.error;

  @doc("The error information.")
  error: InvokeError;
}

import 'package:flutter/widgets.dart';

class NewTabIntent extends Intent {
  const NewTabIntent();
}

class CloseTabIntent extends Intent {
  const CloseTabIntent();
}

class NextTabIntent extends Intent {
  const NextTabIntent();
}

class PreviousTabIntent extends Intent {
  const PreviousTabIntent();
}

class GoToSessionsIntent extends Intent {
  const GoToSessionsIntent();
}

class OpenSettingsIntent extends Intent {
  const OpenSettingsIntent();
}

class ZoomInIntent extends Intent {
  const ZoomInIntent();
}

class ZoomOutIntent extends Intent {
  const ZoomOutIntent();
}

class ResetZoomIntent extends Intent {
  const ResetZoomIntent();
}

class BroadcastInputIntent extends Intent {
  const BroadcastInputIntent();
}

class AiAssistantIntent extends Intent {
  const AiAssistantIntent();
}

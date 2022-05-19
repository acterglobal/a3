abstract class FormSubmissionStatus {
  const FormSubmissionStatus();
}

class InitialFormStatus extends FormSubmissionStatus {
  const InitialFormStatus();
}

class FormSubmitting extends FormSubmissionStatus {}

class SubmissionStatus extends FormSubmissionStatus {}

class SubmissionSuccess extends FormSubmissionStatus {}

class SubmissionFailed extends FormSubmissionStatus {
  final String exception;

  SubmissionFailed(this.exception);
}

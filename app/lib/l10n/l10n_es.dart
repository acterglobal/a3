// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class L10nEs extends L10n {
  L10nEs([String locale = 'es']) : super(locale);

  @override
  String get about => 'Acerca de';

  @override
  String get accept => 'Aceptar';

  @override
  String get acceptRequest => 'Aceptar Petición';

  @override
  String get access => 'Acceso';

  @override
  String get accessAndVisibility => 'Acceso y Visibilidad';

  @override
  String get account => 'Cuenta';

  @override
  String get actionName => 'Nombre de la acción';

  @override
  String get actions => 'Acciones';

  @override
  String activateFeatureDialogTitle(Object feature) {
    return 'Activate $feature?';
  }

  @override
  String activateFeatureDialogDesc(Object feature) {
    return 'Allow anyone with permission following permissions to use $feature';
  }

  @override
  String get add => 'añadir';

  @override
  String get addActionWidget => 'Añadir un widget de acción';

  @override
  String get addChat => 'Añadir Chat';

  @override
  String addedToPusherList(Object email) {
    return '$email añadido a la lista de contactos';
  }

  @override
  String addedToSpacesAndChats(Object number) {
    return 'Añadido a $number espacios y chats';
  }

  @override
  String get addingEmailAddress => 'Añadir una dirección de email';

  @override
  String get addSpace => 'Añadir Espacio';

  @override
  String get addTask => 'Añadir Tarea';

  @override
  String get admin => 'Admin';

  @override
  String get all => 'Todo';

  @override
  String get allMessages => 'Todos los Mensajes';

  @override
  String allReactionsCount(Object total) {
    return 'All $total';
  }

  @override
  String get alreadyConfirmed => 'Ya Confirmado';

  @override
  String get analyticsTitle => 'Help us help you';

  @override
  String get analyticsDescription1 => 'By sharing crash analytics and error reports with us.';

  @override
  String get analyticsDescription2 => 'These are of course anonymized and do not contain any private information';

  @override
  String get sendCrashReportsTitle => 'Send crash & error reports';

  @override
  String get sendCrashReportsInfo => 'Share crash tracebacks via sentry with the Acter team automatically';

  @override
  String get and => 'y';

  @override
  String get anInviteCodeYouWantToRedeem => 'Un código de invitación que desea canjear';

  @override
  String get anyNumber => 'cualquier número';

  @override
  String get appDefaults => 'App por defecto';

  @override
  String get appId => 'AppId';

  @override
  String get appName => 'Nombre de la App';

  @override
  String get apps => 'Características del Espacio';

  @override
  String get areYouSureYouWantToDeleteThisMessage => '¿Está seguro de que quiere borrar este mensaje? Esta acción no se puede deshacer.';

  @override
  String get areYouSureYouWantToLeaveRoom => '¿Está seguro de que desea abandonar el chat? Esta acción no se puede deshacer';

  @override
  String get areYouSureYouWantToLeaveSpace => '¿Está seguro de que quiere abandonar este espacio?';

  @override
  String get areYouSureYouWantToRemoveAttachmentFromPin => '¿Está seguro de que quiere quitar este accesorio de la chincheta?';

  @override
  String get areYouSureYouWantToUnregisterEmailAddress => '¿Está seguro de que desea anular el registro de esta dirección de email? Esta acción no se puede deshacer.';

  @override
  String get assignedYourself => 'asignado a usted mismo';

  @override
  String get assignmentWithdrawn => 'Asignación retirada';

  @override
  String get aTaskMustHaveATitle => 'Una tarea debe tener un título';

  @override
  String get attachments => 'Archivos adjuntos';

  @override
  String get atThisMomentYouAreNotJoiningEvents => 'En este momento, no se está uniendo a ningún evento próximo. Para saber qué eventos están programados, consulte sus espacios.';

  @override
  String get authenticationRequired => 'Autentificación necesaria';

  @override
  String get avatar => 'Avatar';

  @override
  String get awaitingConfirmation => 'En espera de confirmación';

  @override
  String get awaitingConfirmationDescription => 'Estas direcciones de email aún no han sido confirmadas. Por favor, vaya a su bandeja de entrada y busque el enlace de confirmación.';

  @override
  String get back => 'Back';

  @override
  String get block => 'Bloquear';

  @override
  String get blockedUsers => 'Usuarios Bloqueados';

  @override
  String get blockInfoText => 'Una vez bloqueado, ya no verá sus mensajes y se bloqueará cualquier intento de ponerse en contacto con usted directamente.';

  @override
  String blockingUserFailed(Object error) {
    return 'Bloqueo de usuario fallido: $error';
  }

  @override
  String get blockingUserProgress => 'Bloqueo de Usuario';

  @override
  String get blockingUserSuccess => 'Usuario bloqueado. Es posible que la interfaz de usuario tarde un poco en reflejar esta actualización.';

  @override
  String blockTitle(Object userId) {
    return 'Bloquear $userId';
  }

  @override
  String get blockUser => 'Bloquear Usuario';

  @override
  String get blockUserOptional => 'Bloquear Usuario (opcional)';

  @override
  String get blockUserWithUsername => 'Bloquear usuario con nombre de usuario';

  @override
  String get bookmark => 'Marcar como favorito';

  @override
  String get bookmarked => 'Marcado en favoritos';

  @override
  String get bookmarkedSpaces => 'Espacios Marcados en Favoritos';

  @override
  String get builtOnShouldersOfGiants => 'Construido a hombros de gigantes';

  @override
  String get calendarEventsFromAllTheSpaces => 'Calendario de eventos de todos los Espacios de los que usted forma parte';

  @override
  String get calendar => 'Calendar';

  @override
  String get calendarSyncFeatureTitle => 'Calendar Sync';

  @override
  String get calendarSyncFeatureDesc => 'Sync (tentative and accepted) events with device calendar (Android & iOS only)';

  @override
  String get syncThisCalendarTitle => 'Include in Calendar Sync';

  @override
  String get syncThisCalendarDesc => 'Sync these events in the device calendar';

  @override
  String get systemLinksTitle => 'System Links';

  @override
  String get systemLinksExplainer => 'What to do when a link is pressed';

  @override
  String get systemLinksOpen => 'Open';

  @override
  String get systemLinksCopy => 'Copy to Clipboard';

  @override
  String get camera => 'Cámara';

  @override
  String get cancel => 'Cancelar';

  @override
  String get cannotEditSpaceWithNoPermissions => 'No se puede editar espacio sin autorización';

  @override
  String get changeAppLanguage => 'Cambiar el Idioma de la App';

  @override
  String get changePowerLevel => 'Cambiar el Nivel de Acceso';

  @override
  String get changeThePowerLevelOf => 'Cambiar el derecho de acceso a';

  @override
  String get changeYourDisplayName => 'Cambiar su nombre de usuario';

  @override
  String get chat => 'Chat';

  @override
  String get chatNG => 'Next-Generation Chat';

  @override
  String get chatNGExplainer => 'Switch to next generation Chat. Features might not be stable';

  @override
  String get customizationsTitle => 'Customizations';

  @override
  String get chatMissingPermissionsToSend => 'No tiene permisos para enviar mensajes aquí';

  @override
  String get behaviorSettingsTitle => 'Behavior';

  @override
  String get behaviorSettingsExplainer => 'Configure the behavior of your App';

  @override
  String get chatSettingsAutoDownload => 'Descarga Automatica de Archivos Multimedia';

  @override
  String get chatSettingsAutoDownloadExplainer => 'Cuándo descargar archivos multimedia automáticamente';

  @override
  String get chatSettingsAutoDownloadAlways => 'Siempre';

  @override
  String get chatSettingsAutoDownloadWifiOnly => 'Sólo con WiFi';

  @override
  String get chatSettingsAutoDownloadNever => 'Jamás';

  @override
  String get settingsSubmitting => 'Introducir Ajustes';

  @override
  String get settingsSubmittingSuccess => 'Ajustes ingresados';

  @override
  String settingsSubmittingFailed(Object error) {
    return 'Error al enviar: $error ';
  }

  @override
  String get chatRoomCreated => 'Chat Creado';

  @override
  String get chatSendingFailed => 'No se ha podido enviar. Se reintentará ...';

  @override
  String get chatSettingsTyping => 'Enviar notificaciones de tecleo';

  @override
  String get chatSettingsTypingExplainer => '(pronto) Informe a los demás cuando esté escribiendo';

  @override
  String get chatSettingsReadReceipts => 'Enviar comprobante de lectura';

  @override
  String get chatSettingsReadReceiptsExplainer => '(pronto) Informe a los demás cuando lea un mensaje';

  @override
  String get chats => 'Chats';

  @override
  String claimedTimes(Object count) {
    return 'Reclamado $count veces';
  }

  @override
  String get clear => 'Borrar';

  @override
  String get clearDBAndReLogin => 'Borrar la base de datos y volver a iniciar sesión';

  @override
  String get close => 'Cerrar';

  @override
  String get closeDialog => 'Cerrar cuadro de Diálogo';

  @override
  String get closeSessionAndDeleteData => 'Cerrar esta sesión, borrando los datos locales';

  @override
  String get closeSpace => 'Close Space';

  @override
  String get closeChat => 'Close Chat';

  @override
  String get closingRoomTitle => 'Close this Room';

  @override
  String get closingRoomTitleDescription => 'When closing this room, we will :\n\n - Remove everyone with a lower permission level then yours from it\n - Remove it as a child from the parent spaces (where you have the permissions to do so),\n - Set the invite rule to \'private\'\n - You will leave the room.\n\nThis can not be undone. Are you sure you want to close this?';

  @override
  String get closingRoom => 'Closing…';

  @override
  String closingRoomRemovingMembers(Object kicked, Object total) {
    return 'Closing in process. Removing member $kicked / $total';
  }

  @override
  String get closingRoomMatrixMsg => 'The room was closed';

  @override
  String closingRoomRemovingFromParents(Object currentParent, Object totalParents) {
    return 'Closing in process. Removing room from parent $currentParent / $totalParents';
  }

  @override
  String closingRoomDoneBut(Object skipped, Object skippedParents) {
    return 'Closed and you’ve left. But was unable to remove $skipped other Users and remove it as child from $skippedParents Spaces due to lack of permission. Others might still have access to it.';
  }

  @override
  String get closingRoomDone => 'Closed successfully.';

  @override
  String closingRoomFailed(Object error) {
    return 'Closing failed: $error';
  }

  @override
  String get coBudget => 'CoBudget';

  @override
  String get code => 'Código';

  @override
  String get codeMustBeAtLeast6CharactersLong => 'El código debe tener al menos 6 caracteres';

  @override
  String get comment => 'Comentar';

  @override
  String get comments => 'Comentarios';

  @override
  String commentsListError(Object error) {
    return 'Lista de erores de comentarios: $error';
  }

  @override
  String get commentSubmitted => 'Comentario enviado';

  @override
  String get community => 'Comunidad';

  @override
  String get confirmationToken => 'Token de Confirmación';

  @override
  String get confirmedEmailAddresses => 'Direcciones de email confirmadas';

  @override
  String get confirmedEmailAddressesDescription => 'Direcciones de email confirmadas conectadas a su cuenta:';

  @override
  String get confirmWithToken => 'Confirmar con Token';

  @override
  String get congrats => '¡Enhorabuena!';

  @override
  String get connectedToYourAccount => 'Conectado a su cuenta';

  @override
  String get contentSuccessfullyRemoved => 'Contenido eliminado con éxito';

  @override
  String get continueAsGuest => 'Continuar como invitado';

  @override
  String get continueQuestion => '¿Continuar?';

  @override
  String get copyUsername => 'Copiar nombre de usuario';

  @override
  String get copyMessage => 'Copiar';

  @override
  String get couldNotFetchNews => 'No pude buscar noticias';

  @override
  String get couldNotLoadAllSessions => 'No pude cargar todas las sesiones';

  @override
  String couldNotLoadImage(Object error) {
    return 'No pude cargar la imagen debido a $error';
  }

  @override
  String countsMembers(Object count) {
    return '$count Miembros';
  }

  @override
  String get create => 'Crear';

  @override
  String get createChat => 'Crear Chat';

  @override
  String get createCode => 'Crear Código';

  @override
  String get createDefaultChat => 'Create default chat room, too';

  @override
  String defaultChatName(Object name) {
    return '$name chat';
  }

  @override
  String get createDMWhenRedeeming => 'Crear MD al canjear';

  @override
  String get createEventAndBringYourCommunity => 'Cree un nuevo evento y reúna a su comunidad';

  @override
  String get createGroupChat => 'Crear Grupo de Chat';

  @override
  String get createPin => 'Crear Chincheta';

  @override
  String get createPostsAndEngageWithinSpace => 'Cree publicaciones prácticas e involucre a todo el mundo en su espacio.';

  @override
  String get createProfile => 'Crear Perfil';

  @override
  String get createSpace => 'Crear Espacio';

  @override
  String get createSpaceChat => 'Crear Espacio de Chat';

  @override
  String get createSubspace => 'Crear Subespacio';

  @override
  String get createTaskList => 'Crear lista de tareas';

  @override
  String get createAcopy => 'Copy as new';

  @override
  String get creatingCalendarEvent => 'Crear Evento en el Calendario';

  @override
  String get creatingChat => 'Creación de Chat';

  @override
  String get creatingCode => 'Creación de código';

  @override
  String creatingNewsFailed(Object error) {
    return 'Creating update failed $error';
  }

  @override
  String get creatingSpace => 'Creacción de Espacio';

  @override
  String creatingSpaceFailed(Object error) {
    return 'Creacción de espacio fallido: $error';
  }

  @override
  String creatingTaskFailed(Object error) {
    return 'Creación de Tarea Fallida $error';
  }

  @override
  String get custom => 'Personalizado';

  @override
  String get customizeAppsAndTheirFeatures => 'Personalice las características necesarias para este espacio';

  @override
  String get customPowerLevel => 'Nivel de autorización   personalizado';

  @override
  String get dangerZone => 'Zona Peligrosa';

  @override
  String get deactivate => 'Desactivar';

  @override
  String get deactivateAccountDescription => 'Si continúa:\n\n - Todos sus datos personales serán eliminados de su servidor, incluyendo su nombre y avatar. \n - Todas sus sesiones se cerrarán inmediatamente, ningún otro dispositivo podrá continuar sus sesiones \n- Abandonará todas las salas, chats, espacios y DMs en los que se encuentre. \n - No podrá reactivar su cuenta. \n - Ya no podrá iniciar sesión \n - Nadie podrá reutilizar su nombre de usuario (MXID), incluido usted: este nombre de usuario no estará disponible indefinidamente. \n - Se le eliminará del servidor de identidad, si proporcionó alguna información que pudiera encontrarse a través de él (por ejemplo, email o número de teléfono) \n - Todos los datos locales, incluidas las claves de cifrado, se eliminarán permanentemente de este dispositivo. \n - Sus mensajes antiguos seguirán siendo visibles para las personas que los hayan recibido, al igual que los correos electrónicos que enviaste en el pasado. \n\n No podrá revertir nada de esto. Se trata de una acción permanente e irrevocable.';

  @override
  String get deactivateAccountPasswordTitle => 'Indique su contraseña de usuario para confirmar que desea desactivar su cuenta.';

  @override
  String get deactivateAccountTitle => 'Cuidado: Está a punto de desactivar permanentemente su cuenta';

  @override
  String deactivatingFailed(Object error) {
    return 'Desactivación fallida: \n $error';
  }

  @override
  String get deactivatingYourAccount => 'Desactivar su cuenta';

  @override
  String get deactivationAndRemovingFailed => 'Falló la desactivación y eliminación de todos los datos locales';

  @override
  String get debugInfo => 'Información Depurada';

  @override
  String get debugLevel => 'Nivel Depurado';

  @override
  String get decline => 'Rechazar';

  @override
  String get defaultModes => 'Modos Predeterminados';

  @override
  String defaultNotification(Object type) {
    return 'Predeterminado $type';
  }

  @override
  String get delete => 'Eliminar';

  @override
  String get deleteAttachment => 'Eliminar Archivo Adjunto';

  @override
  String get deleteCode => 'Eliminar código';

  @override
  String get deleteTarget => 'Eliminar Objetivo';

  @override
  String get deleteNewsDraftTitle => 'Delete draft?';

  @override
  String get deleteNewsDraftText => 'Are you sure you want to delete this draft? This can’t be undone.';

  @override
  String get deleteDraftBtn => 'Delete draft';

  @override
  String get deletingPushTarget => 'Eliminar el objetivo push';

  @override
  String deletionFailed(Object error) {
    return 'Error de eliminación: $error';
  }

  @override
  String get denied => 'Denegado';

  @override
  String get description => 'Descripción';

  @override
  String get deviceId => 'Identificación del Dispositivo';

  @override
  String get deviceIdDigest => 'Id del Dispositivo Digest';

  @override
  String get deviceName => 'Nombre del Dispositivo';

  @override
  String get devicePlatformException => 'No se puede utilizar DevicePlatform.device/web en este contexto. Plataforma incorrecta: SettingsSection.build';

  @override
  String get displayName => 'Nombre para Mostrar';

  @override
  String get displayNameUpdateSubmitted => 'Actualización del nombre de usuario enviado';

  @override
  String directInviteUser(Object userId) {
    return 'Invitar directamente $userId';
  }

  @override
  String get dms => 'DMs';

  @override
  String get doYouWantToDeleteInviteCode => '¿De verdad quiere borrar irreversiblemente el código de invitación? Después no se podrá volver a utilizar.';

  @override
  String due(Object date) {
    return 'Vencimiento: $date';
  }

  @override
  String get dueDate => 'Fecha de vencimiento';

  @override
  String get edit => 'Editar';

  @override
  String get editDetails => 'Editar Detalles';

  @override
  String get editMessage => 'Editar Mensaje';

  @override
  String get editProfile => 'Editar Perfil';

  @override
  String get editSpace => 'Editar Espacio';

  @override
  String get edited => 'Editado';

  @override
  String get egGlobalMovement => 'ej. Movimiento Global';

  @override
  String get emailAddressToAdd => 'Email para añadir';

  @override
  String get emailOrPasswordSeemsNotValid => 'Parece que el correo electrónico o la contraseña no son válidos.';

  @override
  String get emptyEmail => 'Por favor introduzca su email';

  @override
  String get emptyPassword => 'Por favor introduzca la contraseña';

  @override
  String get emptyToken => 'Por favor introduzca código';

  @override
  String get emptyUsername => 'Por favor introduzca Nombre de Usuario';

  @override
  String get encrypted => 'Encriptado';

  @override
  String get encryptedSpace => 'Espacio Encriptado';

  @override
  String get encryptionBackupEnabled => 'Copias de seguridad cifradas activadas';

  @override
  String get encryptionBackupEnabledExplainer => 'Sus llaves se guardan en una copia de seguridad encriptada en su servidor doméstico';

  @override
  String get encryptionBackupMissing => 'Faltan las copias de seguridad de encriptación';

  @override
  String get encryptionBackupMissingExplainer => 'Recomendamos utilizar copias de seguridad automáticas de las claves de encriptación';

  @override
  String get encryptionBackupProvideKey => 'Proporcionar la clave de recuperación';

  @override
  String get encryptionBackupProvideKeyExplainer => 'Hemos encontrado una copia de seguridad de encriptación automática';

  @override
  String get encryptionBackupProvideKeyAction => 'Proporcionar clave';

  @override
  String get encryptionBackupNoBackup => 'No se ha encontrado ninguna copia de seguridad de encriptación';

  @override
  String get encryptionBackupNoBackupExplainer => 'Si pierde el acceso a su cuenta, las conversaciones podrían resultar irrecuperables. Le recomendamos que active las copias de seguridad automáticas de encriptación.';

  @override
  String get encryptionBackupNoBackupAction => 'Activar copia de seguridad';

  @override
  String get encryptionBackupEnabling => 'Activación de la copia de seguridad';

  @override
  String encryptionBackupEnablingFailed(Object error) {
    return 'Error al activar la copia de seguridad: $error';
  }

  @override
  String get encryptionBackupRecovery => 'Su clave de Seguridad Recuperada';

  @override
  String get encryptionBackupRecoveryExplainer => 'Guarde esta clave de recuperación de copia de seguridad de forma segura.';

  @override
  String get encryptionBackupRecoveryCopiedToClipboard => 'Clave de recuperación copiada en el portapapeles';

  @override
  String get refreshing => 'Refreshing';

  @override
  String get encryptionBackupDisable => '¿Desactivar la Copia de Seguridad de las Claves?';

  @override
  String get encryptionBackupDisableExplainer => 'Restablecer la copia de seguridad de la clave la borrará localmente y de tu servidor doméstico. Esta acción no puede deshacerse. ¿ Está seguro de querer continuar ?';

  @override
  String get encryptionBackupDisableActionKeepIt => 'No, guárdalo';

  @override
  String get encryptionBackupDisableActionDestroyIt => 'Sí, bórralo';

  @override
  String get encryptionBackupResetting => 'Restablecer copia de seguridad';

  @override
  String get encryptionBackupResettingSuccess => 'Restablecimiento correcto';

  @override
  String encryptionBackupResettingFailed(Object error) {
    return 'Error al desactivar: $error';
  }

  @override
  String get encryptionBackupRecover => 'Recuperar copia de seguridad de encriptación';

  @override
  String get encryptionBackupRecoverExplainer => 'Proveer de la clave de recuperación para descifrar la copia de seguridad encriptada';

  @override
  String get encryptionBackupRecoverInputHint => 'Clave de Recuperación';

  @override
  String get encryptionBackupRecoverProvideKey => 'Por favor, facilite la clave';

  @override
  String get encryptionBackupRecoverAction => 'Recuperar';

  @override
  String get encryptionBackupRecoverRecovering => 'Recuperación';

  @override
  String get encryptionBackupRecoverRecoveringSuccess => 'Recuperación satisfactoria';

  @override
  String get encryptionBackupRecoverRecoveringImportFailed => 'Error de importación';

  @override
  String encryptionBackupRecoverRecoveringFailed(Object error) {
    return 'Fallo en la recuperación: $error';
  }

  @override
  String get encryptionBackupKeyBackup => 'Clave de seguridad';

  @override
  String get encryptionBackupKeyBackupExplainer => 'Seleccione aquí la copia de seguridad de su clave';

  @override
  String error(Object error) {
    return 'Error $error';
  }

  @override
  String errorCreatingCalendarEvent(Object error) {
    return 'Error al Crear Un Evento en el Calendario: $error';
  }

  @override
  String errorCreatingChat(Object error) {
    return 'Error al crear chat: $error';
  }

  @override
  String errorSubmittingComment(Object error) {
    return 'Error al enviar comentario: $error';
  }

  @override
  String errorUpdatingEvent(Object error) {
    return 'Error al actualizar el evento: $error';
  }

  @override
  String get eventDescriptionsData => 'Datos de las descripciones de los eventos';

  @override
  String get eventName => 'Nombre del Evento';

  @override
  String get events => 'Eventos';

  @override
  String get eventTitleData => 'Datos del título del evento';

  @override
  String get experimentalActerFeatures => 'Características de Acter Experimental';

  @override
  String failedToAcceptInvite(Object error) {
    return 'No se ha podido aceptar la invitación: $error';
  }

  @override
  String failedToRejectInvite(Object error) {
    return 'No se ha podido rechazar la invitación: $error';
  }

  @override
  String get missingStoragePermissions => 'You must grant us permissions to storage to pick an Image file';

  @override
  String get file => 'Archivo';

  @override
  String get forgotPassword => '¿Olvidó la Contraseña?';

  @override
  String get forgotPasswordDescription => 'Para restablecer su contraseña, le enviaremos un enlace de verificación a su correo electrónico. Siga el proceso y, una vez confirmado, podrá restablecer su contraseña aquí.';

  @override
  String get forgotPasswordNewPasswordDescription => 'Una vez que haya terminado el proceso tras el enlace del correo electrónico que le hemos enviado, puede establecer una nueva contraseña aquí:';

  @override
  String get formatMustBe => 'El formato debe ser @user:server.tld';

  @override
  String get foundUsers => 'Usuarios Encontrados';

  @override
  String get from => 'de';

  @override
  String get gallery => 'Galería';

  @override
  String get general => 'General';

  @override
  String get getConversationGoingToStart => 'Entabla una conversación para empezar a organizar la colaboración';

  @override
  String get getInTouchWithOtherChangeMakers => 'Póngase en contacto con otros agentes del cambio, organizadores o activistas y charle directamente con ellos.';

  @override
  String get goToDM => 'Ir a los MD';

  @override
  String get going => 'Ir';

  @override
  String get haveProfile => '¿Tiene ya un perfil?';

  @override
  String get helpCenterTitle => 'Help Center';

  @override
  String get helpCenterDesc => 'Get helpful tips about Acter';

  @override
  String get hereYouCanChangeTheSpaceDetails => 'Aquí puede cambiar los detalles del espacio';

  @override
  String get hereYouCanSeeAllUsersYouBlocked => 'Aquí puede ver todos los usuarios que ha bloqueado.';

  @override
  String get hintMessageDisplayName => 'Introduzca el nombre que quiere que vean los demás';

  @override
  String get hintMessageInviteCode => 'Introduzca su código de invitación';

  @override
  String get hintMessagePassword => 'Al menos 6 caracteres';

  @override
  String get hintMessageUsername => 'Nombre de usuario único para iniciar sesión e identificarse';

  @override
  String get homeServerName => 'Nombre del Servidor Doméstico';

  @override
  String get homeServerURL => 'Nombre de la URL del Servidor';

  @override
  String get httpProxy => 'Proxy HTTP';

  @override
  String get image => 'Imagen';

  @override
  String get inConnectedSpaces => 'En los espacios conectados, puede centrarse en acciones o campañas específicas de sus grupos de trabajo y empezar a organizarse.';

  @override
  String get info => 'Información';

  @override
  String get invalidTokenOrPassword => 'Contraseña o token inválido';

  @override
  String get invitationToChat => 'Invitado a unirse al chat por ';

  @override
  String get invitationToDM => 'Quiere empezar un MD con usted';

  @override
  String get invitationToSpace => 'Invitado a unirse al espacio por ';

  @override
  String get invited => 'Invitado';

  @override
  String get inviteCode => 'Código de Invitación';

  @override
  String get scanQrCode => 'Scan QR code';

  @override
  String shareInviteWithCode(Object code) {
    return 'Invite $code';
  }

  @override
  String get inviteCodeInfo => 'El acceso a Acter sigue siendo por invitación. En caso de que un grupo o iniciativa específicos no le hayan dado un código de invitación, utilice el siguiente código para visitar Acter.';

  @override
  String get irreversiblyDeactivateAccount => 'Desactivar esta cuenta de forma irreversible';

  @override
  String get itsYou => 'Este es usted';

  @override
  String get join => 'unirse';

  @override
  String get joined => 'Unido';

  @override
  String joiningFailed(Object error) {
    return 'Joining failed: $error';
  }

  @override
  String get joinActer => 'Unirse a Acter';

  @override
  String joinRuleNotSupportedYet(Object role) {
    return 'La regla de ingreso $role aún no es compatible. Lo sentimos';
  }

  @override
  String kickAndBanFailed(Object error) {
    return 'Error al eliminar y banear a un usuario: \n $error';
  }

  @override
  String get kickAndBanProgress => 'Eliminar y Banear a un usuario';

  @override
  String get kickAndBanSuccess => 'Usuario baneado y eliminado';

  @override
  String get kickAndBanUser => 'Eliminar y Banear a un Usuario';

  @override
  String kickAndBanUserDescription(Object roomId, Object userId) {
    return 'Usted está a punto de eliminar y banear permanentemente $userId de $roomId';
  }

  @override
  String kickAndBanUserTitle(Object userId) {
    return 'Eliminar y Banear un Usuario $userId';
  }

  @override
  String kickFailed(Object error) {
    return 'Error al eliminar usuario: \n $error';
  }

  @override
  String get kickProgress => 'Eliminando usuario';

  @override
  String get kickSuccess => 'Usuario eliminado';

  @override
  String get kickUser => 'Eliminar Usuario';

  @override
  String kickUserDescription(Object roomId, Object userId) {
    return 'Está a punto de eliminar $userId de $roomId';
  }

  @override
  String kickUserTitle(Object userId) {
    return 'Eliminar Usuario $userId';
  }

  @override
  String get labs => 'Laboratorios';

  @override
  String get labsAppFeatures => 'Características de la Aplicación';

  @override
  String get language => 'Idioma';

  @override
  String get leave => 'Abandonar';

  @override
  String get leaveRoom => 'Abandonar Chat';

  @override
  String get leaveSpace => 'Abandonar Espacio';

  @override
  String get leavingSpace => 'Abandonando el Espacio';

  @override
  String get leavingSpaceSuccessful => 'Usted ha abandonado el Espacio';

  @override
  String leavingSpaceFailed(Object error) {
    return 'Error al abandonar el espacio: $error';
  }

  @override
  String get leavingRoom => 'Abandonando el Chat';

  @override
  String get letsGetStarted => 'Empecemos';

  @override
  String get licenses => 'Licencias';

  @override
  String get limitedInternConnection => 'Conexión Limitada a internet';

  @override
  String get link => 'Enlace';

  @override
  String get linkExistingChat => 'Enlace al Chat existente';

  @override
  String get linkExistingSpace => 'Enlace al Espacio existente';

  @override
  String get links => 'Enlaces';

  @override
  String get loading => 'Cargando';

  @override
  String get linkToChat => 'Enlace al Chat';

  @override
  String loadingFailed(Object error) {
    return 'Fallo al cargar: $error';
  }

  @override
  String get location => 'Ubicación';

  @override
  String get logIn => 'Iniciar Sesión';

  @override
  String get loginAgain => 'Iniciar Sesión de nuevo';

  @override
  String get loginContinue => 'Inicie sesión y siga organizando desde donde lo dejó la última vez.';

  @override
  String get loginSuccess => 'Inicio de Sesión correcto';

  @override
  String get logOut => 'Cerrar sesión';

  @override
  String get logSettings => 'Ajustes del Registro';

  @override
  String get looksGoodAddressConfirmed => 'Todo parece que está bien. Dirección confirmada.';

  @override
  String get makeADifference => 'Desbloquee su organización digital.';

  @override
  String get manage => 'Gestionar';

  @override
  String get manageBudgetsCooperatively => 'Gestionar los presupuestos en cooperación';

  @override
  String get manageYourInvitationCodes => 'Gestionar sus códigos de invitación';

  @override
  String get markToHideAllCurrentAndFutureContent => 'Marcar para ocultar todo el contenido actual y futuro de este usuario y bloquearlo para que no pueda ponerse en contacto con usted';

  @override
  String get markedAsDone => 'marcado como hecho';

  @override
  String get maybe => 'Quizás';

  @override
  String get member => 'Miembro';

  @override
  String get memberDescriptionsData => 'Datos descriptivos de los miembros';

  @override
  String get memberTitleData => 'Datos del título de miembro';

  @override
  String get members => 'Miembros';

  @override
  String get mentionsAndKeywordsOnly => 'Solo Menciones y Palabras Clave';

  @override
  String get message => 'Mensaje';

  @override
  String get messageCopiedToClipboard => 'Mensaje copiado al portapapeles';

  @override
  String get missingName => 'Por favor introduzca su Nombre';

  @override
  String get mobilePushNotifications => 'Notificaciones Push en el Teléfono';

  @override
  String get moderator => 'Moderador';

  @override
  String get more => 'Más';

  @override
  String moreRooms(Object count) {
    return '+$count additional rooms';
  }

  @override
  String get muted => 'Silenciado';

  @override
  String get customValueMustBeNumber => 'You need to enter the custom value as a number.';

  @override
  String get myDashboard => 'Mi Panel de Control';

  @override
  String get name => 'Nombre';

  @override
  String get nameOfTheEvent => 'Nombre del evento';

  @override
  String get needsAppRestartToTakeEffect => 'Necesita reiniciar la aplicación para que se apliquen los cambios';

  @override
  String get newChat => 'Nuevo Chat';

  @override
  String get newEncryptedMessage => 'Nuevo Mensaje Encriptado';

  @override
  String get needYourPasswordToConfirm => 'Necesita su contraseña para confirmar';

  @override
  String get newMessage => 'Nuevo Mensaje';

  @override
  String get newUpdate => 'Nueva Actualización';

  @override
  String get next => 'Siguiente';

  @override
  String get no => 'No';

  @override
  String get noChatsFound => 'No se han encontrado chats';

  @override
  String get noChatsFoundMatchingYourFilter => 'No se han encontrado chats que coincidan con sus filtros y búsqueda';

  @override
  String get noChatsFoundMatchingYourSearchTerm => 'No se han encontrado chats que coincidan con el término de su búsqueda';

  @override
  String get noChatsInThisSpaceYet => 'Aún sin chats en este espacio';

  @override
  String get noChatsStillSyncing => 'Sincronizando...';

  @override
  String get noChatsStillSyncingSubtitle => 'Estamos cargando sus chats. En cuentas grandes la carga inicial puede tomar un poco de tiempo...';

  @override
  String get noConnectedSpaces => 'Espacios sin conectar';

  @override
  String get noDisplayName => 'No mostrar nombre';

  @override
  String get noDueDate => 'Sin fecha límite';

  @override
  String get noEventsPlannedYet => 'Aún no hay eventos previstos';

  @override
  String get noIStay => 'No, yo me quedo';

  @override
  String get noMembersFound => 'Miembros no encontrados. ¿Cómo puede ser? Usted está aquí, ¿no?';

  @override
  String get noOverwrite => 'No Sobrescribir';

  @override
  String get noParticipantsGoing => 'Ningún participante acudirá';

  @override
  String get noPinsAvailableDescription => 'Comparta recursos importantes con su comunidad, como documentos o enlaces, para que todo el mundo esté al día.';

  @override
  String get noPinsAvailableYet => 'Sin chinchetas disponibles todavía';

  @override
  String get noProfile => '¿Aún no tiene un perfil?';

  @override
  String get noPushServerConfigured => 'No hay servidor push configurado en el sistema';

  @override
  String get noPushTargetsAddedYet => 'aún no se han añadido objetivos push';

  @override
  String get noSpacesFound => 'No se han encontrado espacios';

  @override
  String get noUsersFoundWithSpecifiedSearchTerm => 'No se han encontrado Usuarios con los términos de búsqueda específicos';

  @override
  String get notEnoughPowerLevelForInvites => 'Nivel de permiso insuficiente para las invitaciones, pida al administrador que lo cambie';

  @override
  String get notFound => '404 - Not Found';

  @override
  String get notes => 'Notas';

  @override
  String get notGoing => 'No ir';

  @override
  String get noThanks => 'No, gracias';

  @override
  String get notifications => 'Notificaciones';

  @override
  String get notificationsOverwrites => 'Notificaciones Recargadas';

  @override
  String get notificationsOverwritesDescription => 'Reescribir las configuraciones de tus notificaciones para este espacio';

  @override
  String get notificationsSettingsAndTargets => 'Ajustes y objetivos de las notificaciones';

  @override
  String get notificationStatusSubmitted => 'Estado de la notificación enviado';

  @override
  String notificationStatusUpdateFailed(Object error) {
    return 'Error en la actualización del estado de la notificación: $error';
  }

  @override
  String get notificationsUnmuted => 'Notificaciones silenciadas';

  @override
  String get notificationTargets => 'Objetivos de Notificación';

  @override
  String get notifyAboutSpaceUpdates => 'Notificar sobre las Actualizaciones de Espacios inmediatamente';

  @override
  String get noTopicFound => 'Tema no encontrado';

  @override
  String get notVisible => 'No visible';

  @override
  String get notYetSupported => 'Aún no es compatible';

  @override
  String get noWorriesWeHaveGotYouCovered => '¡No se preocupe! Introduzca su email para restablecer su contraseña.';

  @override
  String get ok => 'Ok';

  @override
  String get okay => 'De acuerdo';

  @override
  String get on => 'en';

  @override
  String get onboardText => 'Empecemos por configurar su perfil';

  @override
  String get onlySupportedIosAndAndroid => 'Por ahora sólo es compatible con móviles (iOS y Android)';

  @override
  String get optional => 'Opcional';

  @override
  String get or => ' o ';

  @override
  String get overview => 'Visión General';

  @override
  String get parentSpace => 'Espacio para Padres';

  @override
  String get parentSpaces => 'Espacios para Padres';

  @override
  String get parentSpaceMustBeSelected => 'El Espacio para Padres debe seleccionarse';

  @override
  String get parents => 'Padres';

  @override
  String get password => 'Contraseña';

  @override
  String get passwordResetTitle => 'Restablecer contraseña';

  @override
  String get past => 'Pasado';

  @override
  String get pending => 'Pendiente';

  @override
  String peopleGoing(Object count) {
    return '$count Gente que va';
  }

  @override
  String get personalSettings => 'Ajustes Personales';

  @override
  String get pinName => 'Nombre de Chincheta';

  @override
  String get pins => 'Chinchetas';

  @override
  String get play => 'Jugar';

  @override
  String get playbackSpeed => 'Velocidad de reproducción';

  @override
  String get pleaseCheckYourInbox => 'Compruebe si ha recibido el email de validación y haga clic en el enlace antes de que caduque';

  @override
  String get pleaseEnterAName => 'Por favor introduzca un nombre';

  @override
  String get pleaseEnterATitle => 'Por favor introduzca un título';

  @override
  String get pleaseEnterEventName => 'Por favor introduzca el nombre del evento';

  @override
  String get pleaseFirstSelectASpace => 'Por favor primero seleccione un espacio';

  @override
  String errorProcessingSlide(Object error, Object slideIdx) {
    return 'We couldn’t process slide $slideIdx: $error';
  }

  @override
  String get pleaseProvideEmailAddressToAdd => 'Por favor proporcione la dirección de email que desee añadir';

  @override
  String get pleaseProvideYourUserPassword => 'Por favor proporcione su contraseña de usuario para confirmar que desea finalizar esa sección.';

  @override
  String get pleaseSelectSpace => 'Por favor seleccione el espacio';

  @override
  String get selectTaskList => 'Select Task List';

  @override
  String get pleaseWait => 'Por favor espere…';

  @override
  String get polls => 'Encuestas';

  @override
  String get pollsAndSurveys => 'Encuestas y Sondeos';

  @override
  String postingOfTypeNotYetSupported(Object type) {
    return 'Publicación de $type aún no admitida';
  }

  @override
  String get postingTaskList => 'Publicación de la Lista de Tareas';

  @override
  String get postpone => 'Aplazar';

  @override
  String postponeN(Object days) {
    return 'Aplazar $days días';
  }

  @override
  String get powerLevel => 'Nivel de Autorización';

  @override
  String get powerLevelUpdateSubmitted => 'Actualización del Nivel de Autorización presentada';

  @override
  String get powerLevelAdmin => 'Admin';

  @override
  String get powerLevelModerator => 'Moderator';

  @override
  String get powerLevelRegular => 'Everyone';

  @override
  String get powerLevelNone => 'None';

  @override
  String get powerLevelCustom => 'Custom';

  @override
  String get powerLevelsTitle => 'General Permission levels';

  @override
  String get powerLevelPostEventsTitle => 'Posting Permission Level';

  @override
  String get powerLevelPostEventsDesc => 'Minimal Permission Level to post anything at all';

  @override
  String get powerLevelKickTitle => 'Kick Permission Level';

  @override
  String get powerLevelKickDesc => 'Minimal Permission Level to kick someone';

  @override
  String get powerLevelBanTitle => 'Ban Permission Level';

  @override
  String get powerLevelBanDesc => 'Minimal Permission Level to ban someone';

  @override
  String get powerLevelInviteTitle => 'Invite Permission Level';

  @override
  String get powerLevelInviteDesc => 'Minimal Permission Level to invite someone';

  @override
  String get powerLevelRedactTitle => 'Redact Permission Level';

  @override
  String get powerLevelRedactDesc => 'Minimal Permission Level to redact other peoples content';

  @override
  String get preview => 'Vista Previa';

  @override
  String get privacyPolicy => 'Política de Privacidad';

  @override
  String get private => 'Privado';

  @override
  String get profile => 'Perfil';

  @override
  String get pushKey => 'PushKey';

  @override
  String get pushTargetDeleted => 'Objetivo Push eliminado';

  @override
  String get pushTargetDetails => 'Detalles del Objetivo Push';

  @override
  String get pushToThisDevice => 'Push en este dispositivo';

  @override
  String get quickSelect => 'Selección Rápida:';

  @override
  String get rageShakeAppName => 'Rageshake Nombre de la Aplicación';

  @override
  String get rageShakeAppNameDigest => 'Rageshake App Name Digest';

  @override
  String get rageShakeTargetUrl => 'Rageshake Objetivo Url';

  @override
  String get rageShakeTargetUrlDigest => 'Rageshake Target Url Digest';

  @override
  String get reason => 'Razón';

  @override
  String get reasonHint => 'razón opcional';

  @override
  String get reasonLabel => 'Razón';

  @override
  String redactionFailed(Object error) {
    return 'El envío de la redacción ha fallado debido a';
  }

  @override
  String get redeem => 'Canjear';

  @override
  String redeemingFailed(Object error) {
    return 'Error en el canje: $error';
  }

  @override
  String get register => 'Registrar';

  @override
  String registerFailed(Object error) {
    return 'Error de registro';
  }

  @override
  String get regular => 'Regular';

  @override
  String get remove => 'Quitar';

  @override
  String get removePin => 'Quitar Pin';

  @override
  String get removeThisContent => 'Eliminar este contenido. Esto no se puede deshacer. Proporcione una razón opcional para explicar por qué se ha eliminado';

  @override
  String get reply => 'Responder';

  @override
  String replyTo(Object name) {
    return 'Responder a $name';
  }

  @override
  String get replyPreviewUnavailable => 'No hay vista previa disponible para el mensaje al que está respondiendo';

  @override
  String get report => 'Informe';

  @override
  String get reportThisEvent => 'Informar de este evento';

  @override
  String get reportThisMessage => 'Informar sobre este mensaje';

  @override
  String get reportMessageContent => 'Informe de este mensaje al administrador de su servidor doméstico. Tenga en cuenta que el administrador no podrá leer ni ver ningún archivo si el chat está encriptado';

  @override
  String get reportPin => 'Informe de Chincheta';

  @override
  String get reportThisPost => 'Informar de esta publicación';

  @override
  String get reportPostContent => 'Informe de esta publicación al administrador de su servidor doméstico. Tenga en cuenta que el administrador no podrá leer ni ver los archivos que se encuentren en espacios encriptados.';

  @override
  String get reportSendingFailed => 'Fallo en el envío de informes';

  @override
  String get reportSent => '¡Informe enviado!';

  @override
  String get reportThisContent => 'Informe de este contenido al administrador de su servidor doméstico. Tenga en cuenta que su administrador no podrá leer ni ver los archivos en espacios encriptados.';

  @override
  String get requestToJoin => 'solicitud de ingreso';

  @override
  String get reset => 'Restablecer';

  @override
  String get resetPassword => 'Restablecer Contraseña';

  @override
  String get retry => 'Reintentar';

  @override
  String get roomId => 'ChatId';

  @override
  String get roomNotFound => 'Chat no encontrado';

  @override
  String get roomLinkedButNotUpgraded => 'Added. However you are not able to upgrade its join rule settings and thus not all people from this space might be able to join it.';

  @override
  String get rsvp => 'RSVP';

  @override
  String repliedToMsgFailed(Object id) {
    return 'Failed to load original message id: $id';
  }

  @override
  String get sasGotIt => 'Lo tengo';

  @override
  String sasIncomingReqNotifContent(String sender) {
    return '$sender quiere verificar su sesión';
  }

  @override
  String get sasIncomingReqNotifTitle => 'Petición de Verificación';

  @override
  String get sasVerified => '¡Verificado!';

  @override
  String get save => 'Guardar';

  @override
  String get saveFileAs => 'Save file as';

  @override
  String get openFile => 'Open';

  @override
  String get shareFile => 'Share';

  @override
  String get saveChanges => 'Guardar Cambios';

  @override
  String get savingCode => 'Código de seguridad';

  @override
  String get search => 'Búsqueda';

  @override
  String get searchTermFieldHint => 'Búsqueda de...';

  @override
  String get searchChats => 'Búsqueda de chats';

  @override
  String searchResultFor(Object text) {
    return 'Resultado de la búsqueda de $text…';
  }

  @override
  String get searchUsernameToStartDM => 'Buscar nombre de usuario para iniciar un MD';

  @override
  String searchingFailed(Object error) {
    return 'Fallo en la búsqueda $error';
  }

  @override
  String get searchSpace => 'buscar espacio';

  @override
  String get searchSpaces => 'Buscar Espacios';

  @override
  String get searchPublicDirectory => 'Buscar en el Directorio Público';

  @override
  String get searchPublicDirectoryNothingFound => 'No se ha encontrado ninguna entrada en el directorio público';

  @override
  String get seeOpenTasks => 'ver tareas abiertas';

  @override
  String get seenBy => 'Visto Por';

  @override
  String get select => 'Seleccionar';

  @override
  String get selectAll => 'Select all';

  @override
  String get unselectAll => 'Unselect all';

  @override
  String get selectAnyRoomToSeeIt => 'Seleccionar Cualquier Chat para ver eso';

  @override
  String get selectDue => 'Seleccionar Vencimiento';

  @override
  String get selectLanguage => 'Seleccionar Idioma';

  @override
  String get selectParentSpace => 'Seleccionar espacio parental';

  @override
  String get send => 'Enviar';

  @override
  String get sendingAttachment => 'Envío de Archivos Adjuntos';

  @override
  String get sendingReport => 'Envío de Informe';

  @override
  String get sendingEmail => 'Envío de Email';

  @override
  String sendingEmailFailed(Object error) {
    return 'Error de envío: $error';
  }

  @override
  String sendingRsvpFailed(Object error) {
    return 'Sending RSVP failed: $error';
  }

  @override
  String get sentAnImage => 'envió una imagen.';

  @override
  String get server => 'Servidor';

  @override
  String get sessions => 'Sesiones';

  @override
  String get sessionTokenName => 'Nombre del Token de la Sesión';

  @override
  String get setDebugLevel => 'Establecer nivel de eliminación';

  @override
  String get setHttpProxy => 'Definir Proxy HTTP';

  @override
  String get settings => 'Ajustes';

  @override
  String get securityAndPrivacy => 'Seguridad y Privacidad';

  @override
  String get settingsKeyBackUpTitle => 'Clave de Seguridad';

  @override
  String get settingsKeyBackUpDesc => 'Gestionar la clave de seguridad';

  @override
  String get share => 'Compartir';

  @override
  String get shareIcal => 'Compartir iCal';

  @override
  String shareFailed(Object error) {
    return 'Error al compartir: $error';
  }

  @override
  String get sharedCalendarAndEvents => 'Calendario y eventos compartidos';

  @override
  String get signUp => 'Inscribirse';

  @override
  String get skip => 'Saltar';

  @override
  String get slidePosting => 'Presentación de diapositivas';

  @override
  String slidesNotYetSupported(Object type) {
    return '$type diapositivas aún incompatibles';
  }

  @override
  String get someErrorOccurredLeavingRoom => 'Se ha producido un error al abandonar el chat';

  @override
  String get space => 'Espacio';

  @override
  String get spaceConfiguration => 'Configuración del Espacio';

  @override
  String get spaceConfigurationDescription => 'Configura, quién puede ver y cómo unirse a este espacio';

  @override
  String get spaceName => 'Nombre del Espacio';

  @override
  String get spaceNotificationOverwrite => 'Sobrescritura de la notificación del espacio';

  @override
  String get spaceNotifications => 'Notificaciones del Espacio';

  @override
  String get spaceOrSpaceIdMustBeProvided => 'el espacio o el identificador del espacio debe ser proporcionado';

  @override
  String get spaces => 'Espacios';

  @override
  String get spacesAndChats => 'Espacios y Chats';

  @override
  String get spacesAndChatsToAddThemTo => 'Espacios y Chats para añadirlos a';

  @override
  String get startDM => 'Iniciar un MD';

  @override
  String get state => 'estado';

  @override
  String get submit => 'Enviar';

  @override
  String get submittingComment => 'Enviar un comentario';

  @override
  String get suggested => 'Suggested';

  @override
  String get suggestedUsers => 'Sugerencias de Usuarios';

  @override
  String get joiningSuggested => 'Joining suggested';

  @override
  String get suggestedRoomsTitle => 'Suggested to join';

  @override
  String get suggestedRoomsSubtitle => 'We suggest you also join the following';

  @override
  String get addSuggested => 'Mark as suggested';

  @override
  String get removeSuggested => 'Remove suggestion';

  @override
  String get superInvitations => 'Códigos de Invitación';

  @override
  String get superInvites => 'Códigos de Invitación';

  @override
  String superInvitedBy(Object user) {
    return '$user te invita';
  }

  @override
  String superInvitedTo(Object count) {
    return 'Unirse a la sala $count';
  }

  @override
  String superInvitesPreviewMissing(Object token) {
    return 'Su servidor no permite previsualizar los códigos de invitación. Sin embargo, puede intentar canjear $token';
  }

  @override
  String superInvitesDeleted(Object token) {
    return 'El código de invitación $token ya no es válido.';
  }

  @override
  String get takeAFirstStep => 'La aplicación de organización segura que crece con tus aspiraciones. Proporcionando un espacio seguro para los movimientos.';

  @override
  String get taskListName => 'Nombre de la lista de tareas';

  @override
  String get tasks => 'Tareas';

  @override
  String get termsOfService => 'Términos del Servicio';

  @override
  String get termsText1 => 'Al hacer clic para crear un perfil, acepta nuestra';

  @override
  String theCurrentJoinRulesOfSpace(Object parentSpaceName, Object roomName) {
    return 'Las reglas de ingreso actuales de $roomName significan que no será visible para los miembros de $parentSpaceName. ¿Deberíamos actualizar las reglas de ingreso para permitir que los miembros del espacio de $parentSpaceName vean y se unan a $roomName?';
  }

  @override
  String get theParentSpace => 'el espacio parental';

  @override
  String get thereIsNothingScheduledYet => 'No hay nada programado todavía';

  @override
  String get theSelectedRooms => 'Los chats seleccionados';

  @override
  String get theyWontBeAbleToJoinAgain => 'Ellos no serán capaces de unirse de nuevo';

  @override
  String get thirdParty => 'terceros';

  @override
  String get thisApaceIsEndToEndEncrypted => 'Este espacio está encriptado de principio a fin';

  @override
  String get thisApaceIsNotEndToEndEncrypted => 'Este espacio no está encriptado de principio a fin';

  @override
  String get thisIsAMultilineDescription => 'Esta es una descripción multilínea de la tarea con textos largos y demás';

  @override
  String get thisIsNotAProperActerSpace => 'Este no es un espacio acter propiamente dicho. Algunas características pueden no estar disponibles.';

  @override
  String get thisMessageHasBeenDeleted => 'Este mensaje ha sido eliminado';

  @override
  String get thisWillAllowThemToContactYouAgain => 'Esto permitirá que puedan volver a contactarte';

  @override
  String get title => 'Título';

  @override
  String get titleTheNewTask => 'Título de la nueva tarea...';

  @override
  String typingUser1(Object user) {
    return '$user está escribiendo...';
  }

  @override
  String typingUser2(Object user1, Object user2) {
    return '$user1 y $user2 están escribiendo...';
  }

  @override
  String typingUserN(Object user, Object userCount) {
    return '$user y $userCount otros están escribiendo';
  }

  @override
  String get to => 'para';

  @override
  String get toAccess => 'to access';

  @override
  String get needToBeMemberOf => 'you need to be member of';

  @override
  String get today => 'Hoy';

  @override
  String get token => 'token';

  @override
  String get tokenAndPasswordMustBeProvided => 'Se deben proporcionar el token y la contraseña';

  @override
  String get tomorrow => 'Mañana';

  @override
  String get topic => 'Tema';

  @override
  String get tryingToConfirmToken => 'Intentando confirmar token';

  @override
  String tryingToJoin(Object name) {
    return 'Intentando unirse a $name';
  }

  @override
  String get tryToJoin => 'Intentar unirse';

  @override
  String get typeName => 'Escriba Nombre';

  @override
  String get unblock => 'Desbloquear';

  @override
  String get unblockingUser => 'Desbloquear Usuario';

  @override
  String unblockingUserFailed(Object error) {
    return 'Fallo al Desbloquear Usuario: $error';
  }

  @override
  String get unblockingUserProgress => 'Desbloquear Usuario';

  @override
  String get unblockingUserSuccess => 'Usuario desbloqueado. Puede que la interfaz de usuario tarde un poco en reflejar esta actualización.';

  @override
  String unblockTitle(Object userId) {
    return 'Desbloquear $userId';
  }

  @override
  String get unblockUser => 'Desbloquear a un Usuario';

  @override
  String unclearJoinRule(Object rule) {
    return 'Regla de adhesión poco clara $rule';
  }

  @override
  String get unreadMarkerFeatureTitle => 'Marcadores Sin Leer';

  @override
  String get unreadMarkerFeatureDescription => 'Seguimiento y visualización de los Chats leídos';

  @override
  String get undefined => 'indefinido';

  @override
  String get unknown => 'desconocido';

  @override
  String get unknownRoom => 'Chat Desconocido';

  @override
  String get unlink => 'Desvincular';

  @override
  String get unmute => 'Reactivar Sonido';

  @override
  String get unset => 'desajustar';

  @override
  String get unsupportedPleaseUpgrade => 'No compatible - ¡Por favor, actualice!';

  @override
  String get unverified => 'Sin verificar';

  @override
  String get unverifiedSessions => 'Sesiones sin Verificar';

  @override
  String get unverifiedSessionsDescription => 'Tiene dispositivos registrados en su cuenta que no están verificados. Esto puede ser un riesgo para la seguridad. Por favor, asegúrese de que esto está bien.';

  @override
  String unverifiedSessionsCount(int count) {
    return 'There are $count unverified sessions logged in';
  }

  @override
  String get upcoming => 'Próximamente';

  @override
  String get updatePowerLevel => 'Actualizar el Nivel de Autorización';

  @override
  String updateFeaturePowerLevelDialogTitle(Object feature) {
    return 'Update Permission of $feature';
  }

  @override
  String updateFeaturePowerLevelDialogFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'from $memberStatus ($currentPowerLevel) to';
  }

  @override
  String get updateFeaturePowerLevelDialogFromDefaultTo => 'from default to';

  @override
  String get updatingDisplayName => 'Actualización del nombre para mostrar';

  @override
  String get updatingDue => 'Actualización Pendiente';

  @override
  String get updatingEvent => 'Actualizando Evento';

  @override
  String updatingPowerLevelOf(Object userId) {
    return 'Actualización del nivel    de Autorización de $userId';
  }

  @override
  String get updatingProfileImage => 'Actualizando imagen del perfil';

  @override
  String get updatingRSVP => 'Actualizando RSVP';

  @override
  String get updatingSpace => 'Actualizando Espacio';

  @override
  String get uploadAvatar => 'Subir Avatar';

  @override
  String usedTimes(Object count) {
    return 'Usado $count veces';
  }

  @override
  String userAddedToBlockList(Object user) {
    return '$user añadido a la lista de bloqueados.La interfaz de usuario puede tomar un poco en actualizarse';
  }

  @override
  String get users => 'Users';

  @override
  String get usersfoundDirectory => 'Usuarios encontrados en el directorio público';

  @override
  String get username => 'Nombre de usuario';

  @override
  String get linkCopiedToClipboard => 'Link copied to clipboard';

  @override
  String get usernameCopiedToClipboard => 'Nombre de Usuario copiado en el portapapeles';

  @override
  String get userRemovedFromList => 'Usuario eliminado de la lista. La interfaz de usuario puede tardar un poco en actualizarse';

  @override
  String get usersYouBlocked => 'Usuarios que usted bloqueó';

  @override
  String get validEmail => 'Por favor introduzca un email válido';

  @override
  String get verificationConclusionCompromised => 'Uno de los siguientes puede estar comprometido:\n\n   - Su servidor doméstico\n   - El servidor doméstico al que está conectado el usuario que usted está verificando.\n   - Su conexión a Internet o la de los otros usuarios.\n   - Su dispositivo o el de los otros usuarios';

  @override
  String verificationConclusionOkDone(String sender) {
    return '¡Ha verificado con éxito a $sender!';
  }

  @override
  String get verificationConclusionOkSelfNotice => 'Su nueva sesión está ahora verificada. Tiene acceso a sus mensajes encriptados, y otros usuarios la verán como de confianza.';

  @override
  String get verificationEmojiNotice => 'Compare los emoji únicos, asegurándose de que aparecen en el mismo orden.';

  @override
  String get verificationRequestAccept => 'Para continuar, acepta la solicitud de verificación en tu otro dispositivo.';

  @override
  String verificationRequestWaitingFor(String sender) {
    return 'Esperando a $sender…';
  }

  @override
  String get verificationSasDoNotMatch => 'No coinciden';

  @override
  String get verificationSasMatch => 'Coinciden';

  @override
  String get verificationScanEmojiTitle => 'No se puede escanear';

  @override
  String get verificationScanSelfEmojiSubtitle => 'Compruébalo comparando los emoji';

  @override
  String get verificationScanSelfNotice => 'Escanee el código con su otro dispositivo o cambie y escanee con este dispositivo';

  @override
  String get verified => 'Verificado';

  @override
  String get verifiedSessionsDescription => 'Todos sus dispositivos están verificados. Su cuenta está segura.';

  @override
  String get verifyOtherSession => 'Verificar otra sesión';

  @override
  String get verifySession => 'Verificar sesión';

  @override
  String get verifyThisSession => 'Verificar esta sesión';

  @override
  String get version => 'Version';

  @override
  String get via => 'por';

  @override
  String get video => 'Vídeo';

  @override
  String get welcomeBack => 'Bienvenido de Nuevo';

  @override
  String get welcomeTo => 'Bienvenido a ';

  @override
  String get whatToCallThisChat => '¿Cómo llamar a este chat?';

  @override
  String get yes => 'Sí';

  @override
  String get yesLeave => 'Sí, Abandonar';

  @override
  String get yesPleaseUpdate => 'Sí, actualizar por favor';

  @override
  String get youAreAbleToJoinThisRoom => 'Puede participar en este chat';

  @override
  String youAreAboutToBlock(Object userId) {
    return 'Está a punto de bloquear a $userId';
  }

  @override
  String youAreAboutToUnblock(Object userId) {
    return 'Está a punto de desbloquear a $userId';
  }

  @override
  String get youAreBothIn => 'you are both in ';

  @override
  String get youAreCurrentlyNotConnectedToAnySpaces => 'Actualmente no está conectado a ningún espacio';

  @override
  String get spaceShortDescription => 'un espacio, ¡para empezar a organizarse y colaborar!';

  @override
  String get youAreDoneWithAllYourTasks => '¡ha acabado con todas sus tareas!';

  @override
  String get youAreNotAMemberOfAnySpaceYet => 'Usted no es miembro de ningún espacio aún';

  @override
  String get youAreNotPartOfThisGroup => 'Usted no es parte de este grupo. ¿Le gustaría unirse?';

  @override
  String get youHaveNoDMsAtTheMoment => 'No tiene MD por el momento';

  @override
  String get youHaveNoUpdates => 'No tienes actualizaciones';

  @override
  String get youHaveNotCreatedInviteCodes => 'No ha creado aún ningún código de invitación';

  @override
  String get youMustSelectSpace => 'Debe seleccionar un espacio';

  @override
  String get youNeedBeInvitedToJoinThisRoom => 'Necesita una invitación para unirse a este Chat';

  @override
  String get youNeedToEnterAComment => 'Necesita introducir un comentario';

  @override
  String get youNeedToEnterCustomValueAsNumber => 'Debe introducir el valor personalizado como un número.';

  @override
  String youCantExceedPowerLevel(Object powerLevel) {
    return 'No puede superar un nivel de autorización de $powerLevel';
  }

  @override
  String get yourActiveDevices => 'Sus dispositivos activos';

  @override
  String get yourPassword => 'Su Contraseña';

  @override
  String get yourSessionHasBeenTerminatedByServer => 'Su sesión ha sido finalizada por el servidor, necesita iniciar sesión de nuevo';

  @override
  String get yourTextSlidesMustContainsSomeText => 'Sus diapositivas deben contener algo de texto';

  @override
  String get yourSafeAndSecureSpace => 'Su espacio seguro para organizar el cambio.';

  @override
  String adding(Object email) {
    return 'añadiendo $email';
  }

  @override
  String get addTextSlide => 'Añadir diapositiva de texto';

  @override
  String get addImageSlide => 'Añadir diapositiva de imagen';

  @override
  String get addVideoSlide => 'Añadir diapositiva de vídeo';

  @override
  String get acter => 'Acter';

  @override
  String get acterApp => 'Applicación Acter';

  @override
  String get activate => 'Activate';

  @override
  String get changingNotificationMode => 'Cambiando el modo de notificación…';

  @override
  String get createComment => 'Crear un Comentario';

  @override
  String get createNewPin => 'Crear una nueva Chincheta';

  @override
  String get createNewSpace => 'Crear un Nuevo Espacio';

  @override
  String get createNewTaskList => 'Crear una nueva lista de tareas';

  @override
  String get creatingPin => 'Creando Chincheta…';

  @override
  String get deactivateAccount => 'Desactivar la Cuenta';

  @override
  String get deletingCode => 'Eliminando código';

  @override
  String get dueToday => 'Vence hoy';

  @override
  String get dueTomorrow => 'Vence Mañana';

  @override
  String get dueSuccess => 'Cambiada fecha de vencimiento con éxito';

  @override
  String get endDate => 'Fecha Final';

  @override
  String get endTime => 'Hora Final';

  @override
  String get emailAddress => 'Dirección de Email';

  @override
  String get emailAddresses => 'Direcciones de Email';

  @override
  String get errorParsinLink => 'Parsing Link failed';

  @override
  String errorCreatingPin(Object error) {
    return 'Un error sucedió creando una chincheta $error';
  }

  @override
  String errorLoadingAttachments(Object error) {
    return 'Error al cargar archivos adjuntos: $error';
  }

  @override
  String errorLoadingAvatar(Object error) {
    return 'Error cargando avatar: $error';
  }

  @override
  String errorLoadingProfile(Object error) {
    return 'Error cargando perfil:$error';
  }

  @override
  String errorLoadingUsers(Object error) {
    return 'Error cargando usuarios: $error';
  }

  @override
  String errorLoadingTasks(Object error) {
    return 'Error cargando tareas: $error';
  }

  @override
  String errorLoadingSpace(Object error) {
    return 'Error al cargar espacio: $error';
  }

  @override
  String errorLoadingRelatedChats(Object error) {
    return 'Error al cargar chats relacionados: $error';
  }

  @override
  String errorLoadingPin(Object error) {
    return 'Error cargando chincheta: $error';
  }

  @override
  String errorLoadingEventDueTo(Object error) {
    return 'Error al cargar el evento debido a: $error';
  }

  @override
  String errorLoadingImage(Object error) {
    return 'Error al cargar imagen: $error';
  }

  @override
  String errorLoadingRsvpStatus(Object error) {
    return 'Error al cargar el estado rsvp: $error';
  }

  @override
  String errorLoadingEmailAddresses(Object error) {
    return 'Error al cargar dirección de email: $error';
  }

  @override
  String errorLoadingMembersCount(Object error) {
    return 'Error al cargar el recuento de miembros: $error';
  }

  @override
  String errorLoadingTileDueTo(Object error) {
    return 'Error al cargar el mosaico debido a: $error';
  }

  @override
  String errorLoadingMember(Object error, Object memberId) {
    return 'Error al cargar el miembro: $memberId $error';
  }

  @override
  String errorSendingAttachment(Object error) {
    return 'Error al enviar archivo adjunto $error';
  }

  @override
  String get eventCreate => 'Crear evento';

  @override
  String get eventEdit => 'Editar evento';

  @override
  String get eventRemove => 'Eliminar evento';

  @override
  String get eventReport => 'Informar de evento';

  @override
  String get eventUpdate => 'Actualizar evento';

  @override
  String get eventShare => 'Compartir evento';

  @override
  String failedToAdd(Object error, Object something) {
    return 'Error al añadir: $error';
  }

  @override
  String failedToChangePin(Object error) {
    return 'Failed to change pin: $error';
  }

  @override
  String failedToChangePowerLevel(Object error) {
    return 'Error al cambiar el nivel de autorización: $error';
  }

  @override
  String failedToChangeNotificationMode(Object error) {
    return 'Error al cambiar el modo de notificación: $error';
  }

  @override
  String failedToChangePushNotificationSettings(Object error) {
    return 'Error al cambiar la configuración de las notificaciones push: $error';
  }

  @override
  String failedToToggleSettingOf(Object error, Object module) {
    return 'Error al cambiar la configuración de $module: $error';
  }

  @override
  String failedToEditSpace(Object error) {
    return 'Error al editar el espacio: $error';
  }

  @override
  String failedToAssignSelf(Object error) {
    return 'Error al asignarse a sí mismo: $error';
  }

  @override
  String failedToUnassignSelf(Object error) {
    return 'Error al desasignarse a sí mismo: $error';
  }

  @override
  String failedToSend(Object error) {
    return 'Error al enviar:$error';
  }

  @override
  String failedToCreateChat(Object error) {
    return 'Error al crear chat:  $error';
  }

  @override
  String failedToCreateTaskList(Object error) {
    return 'Error al crear la lista de tareas:  $error';
  }

  @override
  String failedToConfirmToken(Object error) {
    return 'Error al confirmar el token: $error';
  }

  @override
  String failedToSubmitEmail(Object error) {
    return 'Error al enviar el email: $error';
  }

  @override
  String get failedToDecryptMessage => 'No se ha podido descifrar el mensaje. Vuelva a solicitar las claves de sesión';

  @override
  String failedToDeleteAttachment(Object error) {
    return 'No se ha podido eliminar el archivo adjunto debido a: $error';
  }

  @override
  String get failedToDetectMimeType => 'Error al detectar el tipo mime';

  @override
  String failedToLeaveRoom(Object error) {
    return 'Error al abandonar el Chat $error';
  }

  @override
  String failedToLoadSpace(Object error) {
    return 'Error al cargar el espacio: $error';
  }

  @override
  String failedToLoadEvent(Object error) {
    return 'Error al cargar el evento: $error';
  }

  @override
  String failedToLoadInviteCodes(Object error) {
    return 'Error al cargar códigos de invitación: $error';
  }

  @override
  String failedToLoadPushTargets(Object error) {
    return 'Fallo al cargar objetivos push: $error';
  }

  @override
  String failedToLoadEventsDueTo(Object error) {
    return 'Error al cargar eventos debido a: $error';
  }

  @override
  String failedToLoadChatsDueTo(Object error) {
    return 'Error al cargar los chats debido a: $error';
  }

  @override
  String failedToShareRoom(Object error) {
    return 'Error al compartir este Chat: $error';
  }

  @override
  String get forgotYourPassword => '¿Olvidó su contraseña?';

  @override
  String get editInviteCode => 'Editar Código de Invitación';

  @override
  String get createInviteCode => 'Crear Código de Invitación';

  @override
  String get selectSpacesAndChats => 'Select spaces and chats';

  @override
  String get autoJoinSpacesAndChatsInfo => 'While redeeming this code, selected spaces and chats are auto join.';

  @override
  String get createDM => 'Create DM';

  @override
  String get autoDMWhileRedeemCode => 'While redeeming code, DM will be created\'';

  @override
  String get redeemInviteCode => 'Redeem Invite Code';

  @override
  String saveInviteCodeFailed(Object error) {
    return 'Error al guardar el código: $error';
  }

  @override
  String createInviteCodeFailed(Object error) {
    return 'Error al crear el código: $error';
  }

  @override
  String deleteInviteCodeFailed(Object error) {
    return 'Error al eliminar el código: $error';
  }

  @override
  String get loadingChat => 'Cargando chat…';

  @override
  String get loadingCommentsList => 'Cargando lista de comentarios';

  @override
  String get loadingPin => 'Cargando chincheta';

  @override
  String get loadingRoom => 'Cargando Chat';

  @override
  String get loadingRsvpStatus => 'Cargando estado rsvp';

  @override
  String get loadingTargets => 'Cargando objetivos';

  @override
  String get loadingOtherChats => 'Cargando otros chats';

  @override
  String get loadingFirstSync => 'Cargando primera sincronización';

  @override
  String get loadingImage => 'Cargando imagen';

  @override
  String get loadingVideo => 'Cargando video';

  @override
  String loadingEventsFailed(Object error) {
    return 'Error cargando eventos:$error';
  }

  @override
  String loadingTasksFailed(Object error) {
    return 'Error cargando tareas: $error';
  }

  @override
  String loadingSpacesFailed(Object error) {
    return 'Error al cargar espacios: $error';
  }

  @override
  String loadingRoomFailed(Object error) {
    return 'Error al cargar Salas: $error';
  }

  @override
  String loadingMembersCountFailed(Object error) {
    return 'Error al cargar el recuento de miembros: $error';
  }

  @override
  String get longPressToActivate => 'pulsación larga para activar';

  @override
  String get pinCreatedSuccessfully => 'Chincheta creada con éxito';

  @override
  String get pleaseSelectValidEndTime => 'Por favor seleccione una hora de finalización válida';

  @override
  String get pleaseSelectValidEndDate => 'Por favor seleccione una fecha de finalización válida';

  @override
  String powerLevelSubmitted(Object module) {
    return 'Se ha enviado la actualización del nivel de autorización para $module';
  }

  @override
  String get optionalParentSpace => 'Espacio Parental Opcional';

  @override
  String redeeming(Object token) {
    return 'Canjear $token';
  }

  @override
  String get encryptedDMChat => 'Chat de MD Encriptado';

  @override
  String get encryptedChatMessage => 'Mensaje encriptado bloqueado. Pulse para más';

  @override
  String get encryptedChatMessageInfoTitle => 'Mensaje bloqueado';

  @override
  String get encryptedChatMessageInfo => 'Los mensajes de chat están cifrados de principio a fin. Eso significa que sólo los dispositivos conectados en el momento de enviar el mensaje pueden descifrarlos. Si usted se unió más tarde, acaba de iniciar sesión o utilizó un nuevo dispositivo, aún no tiene las claves para descifrar este mensaje. Podrá obtenerla verificando esta sesión con otro dispositivo de su cuenta, proporcionando una clave de cifrado de reserva o verificando con otro usuario que tenga acceso a la clave.';

  @override
  String get chatMessageDeleted => 'Mensaje borrado';

  @override
  String chatJoinedDisplayName(Object name) {
    return '$name se unió';
  }

  @override
  String chatJoinedUserId(Object userId) {
    return '$userId unido';
  }

  @override
  String get chatYouJoined => 'Usted se unió';

  @override
  String get chatYouLeft => 'You left';

  @override
  String chatYouBanned(Object name) {
    return 'You banned $name';
  }

  @override
  String chatYouUnbanned(Object name) {
    return 'You unbanned $name';
  }

  @override
  String chatYouKicked(Object name) {
    return 'You kicked $name';
  }

  @override
  String chatYouKickedBanned(Object name) {
    return 'You kicked and banned $name';
  }

  @override
  String chatUserLeft(Object name) {
    return '$name left';
  }

  @override
  String chatUserBanned(Object name, Object user) {
    return '$name banned $user';
  }

  @override
  String chatUserUnbanned(Object name, Object user) {
    return '$name unbanned $user';
  }

  @override
  String chatUserKicked(Object name, Object user) {
    return '$name kicked $user';
  }

  @override
  String chatUserKickedBanned(Object name, Object user) {
    return '$name kicked and banned $user';
  }

  @override
  String get chatYouAcceptedInvite => 'Aceptó la invitación';

  @override
  String chatYouInvited(Object name) {
    return 'Invitó';
  }

  @override
  String chatInvitedDisplayName(Object invitee, Object name) {
    return '$name invitado';
  }

  @override
  String chatInvitedUserId(Object inviteeId, Object userId) {
    return '$userId invitado';
  }

  @override
  String chatInvitationAcceptedDisplayName(Object name) {
    return '$name aceptó la invitación';
  }

  @override
  String chatInvitationAcceptedUserId(Object userId) {
    return '$userId aceptó la invitación';
  }

  @override
  String chatDisplayNameUpdate(Object name) {
    return '$name updated display name from';
  }

  @override
  String chatDisplayNameSet(Object name) {
    return '$name set display name';
  }

  @override
  String chatDisplayNameUnset(Object name) {
    return '$name removed display name';
  }

  @override
  String chatUserAvatarChange(Object name) {
    return '$name updated profile avatar';
  }

  @override
  String get dmChat => 'Chat por MD';

  @override
  String get regularSpaceOrChat => 'Espacio Regular o Chat';

  @override
  String get encryptedSpaceOrChat => 'Espacio Encriptado o Chat';

  @override
  String get encryptedChatInfo => 'Todos los mensajes de este chat están encriptados de principio a fin. Nadie ajeno a este chat, ni siquiera Acter o cualquier servidor de Matrix que enrute el mensaje, puede leerlos.';

  @override
  String get removeThisPin => 'Eliminar esta Chincheta';

  @override
  String get removeThisPost => 'Eliminar esta publicación';

  @override
  String get removingContent => 'Eliminar el contenido';

  @override
  String get removingAttachment => 'Eliminar archivo adjunto';

  @override
  String get reportThis => 'Informar de esto';

  @override
  String get reportThisPin => 'Informar de esta Chincheta';

  @override
  String reportSendingFailedDueTo(Object error) {
    return 'El envío del informe ha fallado debido a un $error';
  }

  @override
  String get resettingPassword => 'Reestablecer tu contraseña';

  @override
  String resettingPasswordFailed(Object error) {
    return 'Error de reinicio: $error';
  }

  @override
  String get resettingPasswordSuccessful => 'Restablecimiento de contraseña resuelto con éxito.';

  @override
  String get sharedSuccessfully => 'Compartido con éxito';

  @override
  String get changedPushNotificationSettingsSuccessfully => 'Se ha modificado correctamente la configuración de las notificaciones push';

  @override
  String get startDateRequired => '¡Fecha de inicio requerida!';

  @override
  String get startTimeRequired => '¡Hora de inicio requerida!';

  @override
  String get endDateRequired => '¡Fecha de finalización requerida!';

  @override
  String get endTimeRequired => '¡Tiempo de finalización requerido!';

  @override
  String get searchUser => 'buscar usuario';

  @override
  String seeAllMyEvents(Object count) {
    return 'Ver todos mis $count eventos';
  }

  @override
  String get selectSpace => 'Seleccionar Espacio';

  @override
  String get selectChat => 'Seleccionar Chat';

  @override
  String get selectCustomDate => 'Seleccionar fecha específica';

  @override
  String get selectPicture => 'Seleccionar Foto';

  @override
  String get selectVideo => 'Seleccionar Vídeo';

  @override
  String get selectDate => 'Seleccionar fecha';

  @override
  String get selectTime => 'Seleccionar hora';

  @override
  String get sendDM => 'Enviar MD';

  @override
  String get showMore => 'mostrar más';

  @override
  String get showLess => 'mostrar menos';

  @override
  String get joinSpace => 'Unirse al Espacio';

  @override
  String get joinExistingSpace => 'Unirse al Espacio Existente';

  @override
  String get mySpaces => 'Mis Espacios';

  @override
  String get startDate => 'Fecha de Inicio';

  @override
  String get startTime => 'Hora de Inicio';

  @override
  String get startGroupDM => 'Empezar un Grupo por MD';

  @override
  String get moreSubspaces => 'Mas Subespacios';

  @override
  String get myTasks => 'Mis Tareas';

  @override
  String updatingDueFailed(Object error) {
    return 'Actualización fallida: $error';
  }

  @override
  String get unlinkRoom => 'Desvincular el Chat';

  @override
  String changeThePowerFromTo(Object currentPowerLevel, Object memberStatus) {
    return 'de $memberStatus $currentPowerLevel a';
  }

  @override
  String get createOrJoinSpaceDescription => 'Crear un espacio o unirse a él para empezar a ¡organizarse y colaborar!';

  @override
  String get introPageDescriptionPre => 'Acter is more than just an app.\nIt’s';

  @override
  String get isLinked => 'is linked in here';

  @override
  String get canLink => 'You can link this';

  @override
  String get canLinkButNotUpgrade => 'You can link this, but not update its join permissions';

  @override
  String get introPageDescriptionHl => ' community of change makers.';

  @override
  String get introPageDescriptionPost => ' ';

  @override
  String get introPageDescription2ndLine => 'Connect with fellow activists, share insights, and collaborate on creating meaningful change.';

  @override
  String get logOutConformationDescription1 => 'Atención: ';

  @override
  String get logOutConformationDescription2 => 'Al cerrar la sesión se eliminan los datos locales, incluidas las claves de cifrado. Si este es el último dispositivo en el que ha iniciado sesión, es posible que no pueda descifrar ningún contenido anterior.';

  @override
  String get logOutConformationDescription3 => ' ¿Está seguro de que quiere salir de la sesión?';

  @override
  String membersCount(Object count) {
    return '$count Miembros';
  }

  @override
  String get renderSyncingTitle => 'Sincronización con su servidor doméstico';

  @override
  String get renderSyncingSubTitle => 'Esto puede llevar un tiempo si tiene una cuenta grande';

  @override
  String errorSyncing(Object error) {
    return 'Error de sincronización: $error';
  }

  @override
  String get retrying => 'reintentando …';

  @override
  String retryIn(Object minutes, Object seconds) {
    return 'Reintentará en $minutes:$seconds';
  }

  @override
  String get invitations => 'Invitaciones';

  @override
  String invitingLoading(Object userId) {
    return 'Invitando a $userId';
  }

  @override
  String invitingError(Object error, Object userId) {
    return 'Usuario $userId no encontrado o existente: $error';
  }

  @override
  String get invite => 'Invitar';

  @override
  String errorUnverifiedSessions(Object error) {
    return 'No se han podido cargar sesiones no verificadas: $error';
  }

  @override
  String unverifiedSessionsTitle(Object count) {
    return 'Hay $count sesiones no verificadas conectadas';
  }

  @override
  String get review => 'Revisar';

  @override
  String get activities => 'Actividades';

  @override
  String get activitiesDescription => 'Todas las cosas importantes que requieren su atención pueden ser encontradas aquí';

  @override
  String get noActivityTitle => 'Ninguna actividad para usted todavía';

  @override
  String get noActivitySubtitle => 'Le notifica cosas importantes, como mensajes, invitaciones o solicitudes.';

  @override
  String get joining => 'Uniéndose';

  @override
  String get joinedDelayed => 'Invitación aceptada, aunque la confirmación tarda en llegar';

  @override
  String get rejecting => 'Rechazar';

  @override
  String get rejected => 'Rechazado';

  @override
  String get failedToReject => 'Rechazo fallido';

  @override
  String reportedBugSuccessful(Object issueId) {
    return '¡Error reportado con éxito! (#$issueId)';
  }

  @override
  String get thanksForReport => '¡Gracias por informar de ese error!';

  @override
  String bugReportingError(Object error) {
    return 'Error al reportar un error: $error';
  }

  @override
  String get bugReportTitle => 'Informar de un problema';

  @override
  String get bugReportDescription => 'Breve descripción de la cuestión';

  @override
  String get emptyDescription => 'Por favor, introduzca la descripción';

  @override
  String get includeUserId => 'Incluir mi ID de Matrix';

  @override
  String get includeLog => 'Incluir registros actuales';

  @override
  String get includePrevLog => 'Incluir registros de la ronda anterior';

  @override
  String get includeScreenshot => 'Incluir captura de pantalla';

  @override
  String get includeErrorAndStackTrace => 'Include Error & Stacktrace';

  @override
  String get jumpTo => 'saltar a';

  @override
  String get noMatchingPinsFound => 'sin resultados encontrados de chinchetas';

  @override
  String get update => 'Actualizar';

  @override
  String get event => 'Evento';

  @override
  String get taskList => 'Lista de Tareas';

  @override
  String get pin => 'Chincheta';

  @override
  String get poll => 'Encuesta';

  @override
  String get discussion => 'Debate';

  @override
  String get fatalError => 'Error Grave';

  @override
  String get nukeLocalData => 'Destruir datos locales';

  @override
  String get reportBug => 'Informar de un fallo';

  @override
  String get somethingWrong => 'Algo salió muy mal:';

  @override
  String get copyToClipboard => 'Copiar al Portapapeles';

  @override
  String get errorCopiedToClipboard => 'Error y Stacktrace copiados en el portapapeles';

  @override
  String get showStacktrace => 'Mostrar Stacktrace';

  @override
  String get hideStacktrace => 'Ocultar Stacktrace';

  @override
  String get sharingRoom => 'Compartir este Chat…';

  @override
  String get changingSettings => 'Cambiar ajustes…';

  @override
  String changingSettingOf(Object module) {
    return 'Cambiar ajustes de $module';
  }

  @override
  String changedSettingOf(Object module) {
    return 'Cambiado ajustes de $module';
  }

  @override
  String changingPowerLevelOf(Object module) {
    return 'Cambio nivel de autorización de $module';
  }

  @override
  String get assigningSelf => 'Asignarse a sí mismo…';

  @override
  String get unassigningSelf => 'Desasignarse a sí mismo…';

  @override
  String get homeTabTutorialTitle => 'Panel de Control';

  @override
  String get homeTabTutorialDescription => 'Aquí encontrará sus espacios y una visión general de todos los próximos eventos y tareas pendientes de estos espacios.';

  @override
  String get updatesTabTutorialTitle => 'Actualizaciones';

  @override
  String get updatesTabTutorialDescription => 'Flujo de noticias sobre las últimas actualizaciones y llamadas a la acción de sus espacios.';

  @override
  String get chatsTabTutorialTitle => 'Chats';

  @override
  String get chatsTabTutorialDescription => 'Es el lugar para chatear, ya sea en grupo o individualmente. Los chats pueden enlazarse con distintos espacios para ampliar la colaboración.';

  @override
  String get activityTabTutorialTitle => 'Actividad';

  @override
  String get activityTabTutorialDescription => 'Información importante de sus espacios, como invitaciones o solicitudes. Además, recibirá notificaciones de Acter sobre problemas de seguridad';

  @override
  String get jumpToTabTutorialTitle => 'Saltar a';

  @override
  String get jumpToTabTutorialDescription => 'Su búsqueda sobre espacios y chinchetas, así como acciones rápidas y acceso rápido a varias secciones';

  @override
  String get createSpaceTutorialTitle => 'Crear Nuevo Espacio';

  @override
  String get createSpaceTutorialDescription => 'Únase a un espacio existente en nuestro servidor Acter o en el universo Matrix o cree su propio espacio.';

  @override
  String get joinSpaceTutorialTitle => 'Unirse a un Espacio Existente';

  @override
  String get joinSpaceTutorialDescription => 'Únase a un espacio existente en nuestro servidor Acter o en el universo Matrix o cree su propio espacio. [sólo mostraría las opciones y terminaría ahí por ahora]';

  @override
  String get spaceOverviewTutorialTitle => 'Destalles del Espacio';

  @override
  String get spaceOverviewTutorialDescription => 'Un espacio es el punto de partida de su organización. Cree y navegue a través de chinchetas (recursos), tareas y eventos. Añada chats o subespacios.';

  @override
  String get subscribedToParentMsg => 'Disable Notifications on main object to configure notification here';

  @override
  String get parentSubscribedAction => 'Notifications active through object';

  @override
  String get subscribeAction => 'Activate Notifications';

  @override
  String get unsubscribeAction => 'De-Activate Notifications';

  @override
  String get commentEmptyStateTitle => 'No hay comentarios encontrados.';

  @override
  String get commentEmptyStateAction => 'Deje el primer comentario';

  @override
  String get previous => 'Anterior';

  @override
  String get finish => 'Acabar';

  @override
  String get saveUsernameTitle => '¿Ha guardo su nombre de usuario?';

  @override
  String get saveUsernameDescription1 => 'Recuerde anotar su nombre de usuario. Es la clave para acceder a su perfil y a toda la información y espacios relacionados con él.';

  @override
  String get saveUsernameDescription2 => 'Su nombre de usuario es crucial para restablecer la contraseña.';

  @override
  String get saveUsernameDescription3 => 'Sin ella, el acceso a su perfil y a su progreso se perderá permanentemente.';

  @override
  String get acterUsername => 'Su nombre de usuario Acter';

  @override
  String get autoSubscribeFeatureDesc => 'upon creation or interaction with objects';

  @override
  String get autoSubscribeSettingsTitle => 'Automatically subscribe ';

  @override
  String get copyToClip => 'Copiar al Portapapeles';

  @override
  String get wizzardContinue => 'Continuar';

  @override
  String get protectPrivacyTitle => 'Proteger tu privacidad';

  @override
  String get protectPrivacyDescription1 => 'En Acter, mantener su cuenta segura es importante. Por eso puede usarla sin vincular su perfil a su email para mayor privacidad y protección.';

  @override
  String get protectPrivacyDescription2 => 'Pero si lo prefiere, puede enlazarlos, por ejemplo, para recuperar contraseñas.';

  @override
  String get linkEmailToProfile => 'Email vinculado al Perfil';

  @override
  String get emailOptional => 'Email (Opcional)';

  @override
  String get hintEmail => 'Introduzca su dirección de email';

  @override
  String get linkingEmailAddress => 'Vincular su dirección de email';

  @override
  String get avatarAddTitle => 'Añadir Avatar de Usuario';

  @override
  String get avatarEmpty => 'Por favor seleccione su avatar';

  @override
  String get avatarUploading => 'Subir avatar de perfil';

  @override
  String avatarUploadFailed(Object error) {
    return 'Fallo al cargar el avatar del usuario: $error';
  }

  @override
  String get sendEmail => 'Enviar email';

  @override
  String get inviteCopiedToClipboard => 'Código de invitación pegado al portapapeles';

  @override
  String get updateName => 'Actualizar nombre';

  @override
  String get updateDescription => 'Actualizar descripción';

  @override
  String get editName => 'Editar Nombre';

  @override
  String get editDescription => 'Editar Descripción';

  @override
  String updateNameFailed(Object error) {
    return 'Error al actualizar nombre: $error';
  }

  @override
  String updateDescriptionFailed(Object error) {
    return 'Error al actualizar descripción: $error';
  }

  @override
  String get eventParticipants => 'Participantes del Evento';

  @override
  String get upcomingEvents => 'Eventos Próximos';

  @override
  String get spaceInviteDescription => '¿Le gustaría invitar a alguien a este espacio?';

  @override
  String get inviteSpaceMembersTitle => 'Invitar a Miembros al Espacio';

  @override
  String get inviteSpaceMembersSubtitle => 'Invitar a usuarios del espacio seleccionado';

  @override
  String get inviteIndividualUsersTitle => 'Invitar a Usuarios Individuales';

  @override
  String get inviteIndividualUsersSubtitle => 'Invitar a usuarios que están ya en Acter';

  @override
  String get inviteIndividualUsersDescription => 'Invitar a alguien que ya forma parte de la plataforma Acter';

  @override
  String get inviteJoinActer => 'Invitar a unirse a Acter';

  @override
  String get inviteJoinActerDescription => 'Puede invitar a la gente a unirse a Acter y unirse automáticamente a este espacio con un código de registro personalizado y compartirlo con ellos';

  @override
  String get generateInviteCode => 'Generar Código de Invitación';

  @override
  String get pendingInvites => 'Invitaciones Pendiente';

  @override
  String pendingInvitesCount(Object count) {
    return 'You have $count pending Invites';
  }

  @override
  String get noPendingInvitesTitle => 'No se han encontrado invitaciones pendientes';

  @override
  String get noUserFoundTitle => 'No se han encontrado usuarios';

  @override
  String get noUserFoundSubtitle => 'Buscar usuarios por sus nombres de usuario o por nombre que se muestra';

  @override
  String get done => 'Hecho';

  @override
  String get downloadFileDialogTitle => 'Por favor seleccione donde guardar el archivo';

  @override
  String downloadFileSuccess(Object path) {
    return 'Archivo guardado en $path';
  }

  @override
  String cancelInviteLoading(Object userId) {
    return 'Cancelando invitación de $userId';
  }

  @override
  String cancelInviteError(Object error, Object userId) {
    return 'Usuario $userId no encontrado: $error';
  }

  @override
  String get shareInviteCode => 'Compartir Código de Invitación';

  @override
  String get appUnavailable => 'Aplicación no disponible';

  @override
  String shareInviteContent(Object code, Object roomName, Object userName) {
    return '$userName desea invitarle a la $roomName.\nPor favor, siga los siguientes pasos para unirse:\n\nPASO-1: Descargue la aplicación Acter desde los siguientes enlaces https://app-redir.acter.global/\n\nPASO-2: Utilice el siguiente código de invitación en el registro.\nCódigo de invitación : $code\n\n¡Eso es todo! ¡Disfrute de la nueva forma segura de organizarse!';
  }

  @override
  String activateInviteCodeFailed(Object error) {
    return 'Código de activación fallido: $error';
  }

  @override
  String get revoke => 'Revocar';

  @override
  String get otherSpaces => 'Otros Espacios';

  @override
  String get invitingSpaceMembersLoading => 'Invitar a los miembros del Espacio';

  @override
  String invitingSpaceMembersProgress(Object count, Object total) {
    return 'Inviting Space Member $count / $total';
  }

  @override
  String invitingSpaceMembersError(Object error) {
    return 'Error al invitar a Miembros del Espacio: $error';
  }

  @override
  String membersInvited(Object count) {
    return '$count miembros invitados';
  }

  @override
  String get selectVisibility => 'Seleccione Visibilidad';

  @override
  String get visibilityTitle => 'Visibilidad';

  @override
  String get visibilitySubtitle => 'Seleccione quien puede unirse a este espacio.';

  @override
  String get visibilityNoPermission => 'No tienes los permisos necesarios para cambiar la visibilidad de este espacio';

  @override
  String get public => 'Público';

  @override
  String get publicVisibilitySubtitle => 'Cualquiera puede encontrarlo y unirse';

  @override
  String get privateVisibilitySubtitle => 'Solo gente invitada puede unirse';

  @override
  String get limited => 'Limitado';

  @override
  String get limitedVisibilitySubtitle => 'Cualquiera en los espacios seleccionados puede encontrarlos y unirse';

  @override
  String get visibilityAndAccessibility => 'Visibilidad y Accesibilidad';

  @override
  String updatingVisibilityFailed(Object error) {
    return 'Updating room visibility failed: $error';
  }

  @override
  String get spaceWithAccess => 'Espacio con acceso';

  @override
  String get changePassword => 'Cambiar Contraseña';

  @override
  String get changePasswordDescription => 'Cambiar tu Contraseña';

  @override
  String get oldPassword => 'Contraseña Antigua';

  @override
  String get newPassword => 'Contraseña Nueva';

  @override
  String get confirmPassword => 'Confirmar Contraseña';

  @override
  String get emptyOldPassword => 'Por favor introduzca la contraseña antigua';

  @override
  String get emptyNewPassword => 'Por favor introduzca la contraseña nueva';

  @override
  String get emptyConfirmPassword => 'Por favor confirme la contraseña';

  @override
  String get validateSamePassword => 'La contraseña debe ser la misma';

  @override
  String get changingYourPassword => 'Cambie su contraseña';

  @override
  String changePasswordFailed(Object error) {
    return 'Error al cambiar la contraseña: $error';
  }

  @override
  String get passwordChangedSuccessfully => 'Contraseña cambiada satisfactoriamente';

  @override
  String get emptyTaskList => 'Aún no se ha creado ninguna lista de Tareas';

  @override
  String get addMoreDetails => 'Añadir Más Detalles';

  @override
  String get taskName => 'Nombre de Tarea';

  @override
  String get addingTask => 'Añadir Tarea';

  @override
  String countTasksCompleted(Object count) {
    return '$count Completado';
  }

  @override
  String get showCompleted => 'Mostrar Completado';

  @override
  String get hideCompleted => 'Ocultar Completado';

  @override
  String get assignment => 'Asignación';

  @override
  String get noAssignment => 'Sin Asignación';

  @override
  String get assignMyself => 'Asignar a mí mismo';

  @override
  String get removeMyself => 'Eliminar a mí mismo';

  @override
  String get updateTask => 'Actualizar Tarea';

  @override
  String get updatingTask => 'Actualizando Tarea';

  @override
  String updatingTaskFailed(Object error) {
    return 'Error Actualizando Tarea $error';
  }

  @override
  String get editTitle => 'Editar Título';

  @override
  String get updatingDescription => 'Actualizando Descripción';

  @override
  String errorUpdatingDescription(Object error) {
    return 'Error actualizando descripción: $error';
  }

  @override
  String get editLink => 'Editar Link';

  @override
  String get updatingLinking => 'Actualizando link';

  @override
  String get deleteTaskList => 'Eliminar Lista de Tareas';

  @override
  String get deleteTaskItem => 'Eliminar Elemento de la Tarea';

  @override
  String get reportTaskList => 'Informar de la Lista de Tareas';

  @override
  String get reportTaskItem => 'Informar de Elemento de la Tarea';

  @override
  String get unconfirmedEmailsActivityTitle => 'Tienes una Dirección de Email sin confirmar';

  @override
  String get unconfirmedEmailsActivitySubtitle => 'Siga el enlace que le hemos enviado por email y confírmelos aquí';

  @override
  String get seeAll => 'Ver todo';

  @override
  String get addPin => 'Añadir Chincheta';

  @override
  String get addEvent => 'Añadir Evento';

  @override
  String get linkChat => 'Vincular Chat';

  @override
  String get linkSpace => 'Vincular Espacio';

  @override
  String failedToUploadAvatar(Object error) {
    return 'Failed to upload avatar: $error';
  }

  @override
  String get noMatchingTasksListFound => 'No matching tasks list found';

  @override
  String get noTasksListAvailableYet => 'No tasks list available yet';

  @override
  String get noTasksListAvailableDescription => 'Share and manage important task with your community such as any TO-DO list so everyone is updated.';

  @override
  String loadingMembersFailed(Object error) {
    return 'Error al cargar miembros: $error';
  }

  @override
  String get ongoing => 'Ongoing';

  @override
  String get noMatchingEventsFound => 'No matching events found';

  @override
  String get noEventsFound => 'No events found';

  @override
  String get noEventAvailableDescription => 'Create new event and bring your community together.';

  @override
  String get myEvents => 'My Events';

  @override
  String get eventStarted => 'Started';

  @override
  String get eventStarts => 'Starts';

  @override
  String get eventEnded => 'Ended';

  @override
  String get happeningNow => 'Happening Now';

  @override
  String get myUpcomingEvents => 'My Upcoming Events';

  @override
  String get live => 'Live';

  @override
  String get forbidden => 'Forbidden';

  @override
  String get forbiddenRoomExplainer => 'Access to the room has been denied. Please contact the author to be invited';

  @override
  String accessDeniedToRoom(Object roomId) {
    return 'Access to $roomId denied';
  }

  @override
  String get changeDate => 'Change Date';

  @override
  String deepLinkNotSupported(Object link) {
    return 'Link $link not supported';
  }

  @override
  String get deepLinkWrongFormat => 'Not a link. Can\'t open.';

  @override
  String get updatingDate => 'Updating Date';

  @override
  String get pleaseEnterALink => 'Please enter a link';

  @override
  String get pleaseEnterAValidLink => 'Please enter a valid link';

  @override
  String get addLink => 'Add Link';

  @override
  String get attachmentEmptyStateTitle => 'No attachments found.';

  @override
  String get referencesEmptyStateTitle => 'No references found.';

  @override
  String get text => 'text';

  @override
  String get audio => 'Audio';

  @override
  String get pinDetails => 'Pin Details';

  @override
  String get inSpaceLabelInline => 'In:';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get colonCharacter => ' : ';

  @override
  String get andSeparator => ' and ';

  @override
  String andNMore(Object count) {
    return ', and $count more';
  }

  @override
  String errorLoadingSpaces(Object error) {
    return 'Error al cargar espacios: $error';
  }

  @override
  String get eventNoLongerAvailable => 'Event no longer available';

  @override
  String get eventDeletedOrFailedToLoad => 'This may due to event deletion or failed to load';

  @override
  String get chatNotEncrypted => 'This chat is not end-to-end-encrypted';

  @override
  String get updatingIcon => 'Updating Icon';

  @override
  String get selectColor => 'Select color';

  @override
  String get selectIcon => 'Select icon';

  @override
  String get createCategory => 'Create Category';

  @override
  String get organize => 'Organize';

  @override
  String get updatingCategories => 'Updating categories';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String updatingCategoriesFailed(Object error) {
    return 'Updating categories failed $error';
  }

  @override
  String get addingNewCategory => 'Adding new category';

  @override
  String addingNewCategoriesFailed(Object error) {
    return 'Adding new category failed $error';
  }

  @override
  String get action => 'Action';

  @override
  String get addCategory => 'Add Category';

  @override
  String get editCategory => 'Edit Category';

  @override
  String get deleteCategory => 'Delete Category';

  @override
  String get boost => 'Boost';

  @override
  String get boosts => 'Boosts';

  @override
  String get requiredPowerLevel => 'Required PowerLevel';

  @override
  String minPowerLevelDesc(Object featureName) {
    return 'Minimum power level required to post $featureName';
  }

  @override
  String get minPowerLevelRsvp => 'Minimum power level to RSVP to calendar events';

  @override
  String get commentsOnBoost => 'Comments on Boost';

  @override
  String get commentsOnPin => 'Comments on Pin';

  @override
  String get adminPowerLevel => 'Admin PowerLevel';

  @override
  String get rsvpPowerLevel => 'RSVP PowerLevel';

  @override
  String get taskListPowerLevel => 'TaskList PowerLevel';

  @override
  String get tasksPowerLevel => 'Tasks PowerLevel';

  @override
  String get appSettings => 'App Settings';

  @override
  String get activeApps => 'Active Apps';

  @override
  String get postSpaceWiseBoost => 'Post space-wide boost';

  @override
  String get pinImportantInformation => 'Pin important information';

  @override
  String get calenderWithEvents => 'Calender with Events';

  @override
  String get pinNoLongerAvailable => 'Pin no longer available';

  @override
  String get inviteCodeEmptyState => 'No invite codes are generated yet';

  @override
  String get pinDeletedOrFailedToLoad => 'This may due to pin deletion or failed to load';

  @override
  String get sharePin => 'Compartir Chincheta';

  @override
  String get selectPin => 'Select Pin';

  @override
  String get selectEvent => 'Select Event';

  @override
  String get shareTaskList => 'Share TaskList';

  @override
  String get shareSpace => 'Share Space';

  @override
  String get shareChat => 'Share Chat';

  @override
  String get addBoost => 'Add Boost';

  @override
  String get addTaskList => 'Add TaskList';

  @override
  String get task => 'Task';

  @override
  String get signal => 'Signal';

  @override
  String get whatsApp => 'WhatsApp';

  @override
  String get whatsAppBusiness => 'WA Business';

  @override
  String get telegram => 'Telegram';

  @override
  String get copy => 'copy';

  @override
  String get copyLink => 'Copy Link';

  @override
  String get qr => 'QR';

  @override
  String get newBoost => 'New\nBoost';

  @override
  String get addComment => 'Add Comment';

  @override
  String get references => 'References';

  @override
  String get removeReference => 'Remove Reference';

  @override
  String get suggestedChats => 'Suggested Chats';

  @override
  String get suggestedSpaces => 'Suggested Spaces';

  @override
  String get removeReferenceConfirmation => 'Are you sure you want to remove this reference?';

  @override
  String noObjectAccess(Object objectType, Object spaceName) {
    return 'You are not part of $spaceName so you can\'t access this $objectType';
  }

  @override
  String get shareLink => 'Share link';

  @override
  String get shareSuperInvite => 'Share Invitation Code';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get unableToLoadVideo => 'Unable to load video';

  @override
  String get unableToLoadImage => 'Unable to load image';

  @override
  String get unableToLoadFile => 'Unable to load file';
}

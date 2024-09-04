import 'package:flutter/cupertino.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum ActerIcons {
  //LIST OF ACTER ICONS
  list(PhosphorIconsRegular.list),
  pin(PhosphorIconsRegular.pushPin),
  airplane(PhosphorIconsRegular.airplane),
  addressBook(PhosphorIconsRegular.addressBook),
  airplay(PhosphorIconsRegular.airplay),
  alarm(PhosphorIconsRegular.alarm),
  amazonLogo(PhosphorIconsRegular.amazonLogo),
  ambulance(PhosphorIconsRegular.ambulance),
  anchor(PhosphorIconsRegular.anchor),
  appleLogo(PhosphorIconsRegular.appleLogo),
  aperture(PhosphorIconsRegular.aperture),
  archive(PhosphorIconsRegular.archive),
  appStoreLogo(PhosphorIconsRegular.appStoreLogo),
  baby(PhosphorIconsRegular.baby),
  bag(PhosphorIconsRegular.bag),
  backpack(PhosphorIconsRegular.backpack),
  bank(PhosphorIconsRegular.bank),
  balloon(PhosphorIconsRegular.balloon),
  barcode(PhosphorIconsRegular.barcode),
  basketball(PhosphorIconsRegular.basketball),
  bathtub(PhosphorIconsRegular.bathtub),
  batteryCharging(PhosphorIconsRegular.batteryCharging),
  beanie(PhosphorIconsRegular.beanie),
  bed(PhosphorIconsRegular.bed),
  bell(PhosphorIconsRegular.bell),
  bicycle(PhosphorIconsRegular.bicycle),
  brain(PhosphorIconsRegular.brain),
  boat(PhosphorIconsRegular.boat),
  book(PhosphorIconsRegular.book),
  bird(PhosphorIconsRegular.bird),
  browser(PhosphorIconsRegular.browser),
  bookmark(PhosphorIconsRegular.bookmark),
  bomb(PhosphorIconsRegular.bomb),
  broadcast(PhosphorIconsRegular.broadcast),
  boot(PhosphorIconsRegular.boot),
  cableCar(PhosphorIconsRegular.cableCar),
  cactus(PhosphorIconsRegular.cactus),
  cake(PhosphorIconsRegular.cake),
  calculator(PhosphorIconsRegular.calculator),
  calendar(PhosphorIconsRegular.calendar),
  callBell(PhosphorIconsRegular.callBell),
  camera(PhosphorIconsRegular.camera),
  car(PhosphorIconsRegular.car),
  cat(PhosphorIconsRegular.cat),
  chat(PhosphorIconsRegular.chat),
  check(PhosphorIconsRegular.check),
  yarn(PhosphorIconsRegular.yarn);
  //..

  //ICON ACCESS METHODS
  static IconData? iconDataFor(String? name) =>
      ActerIcons.values.asNameMap()[name]?.data;

  static IconData iconDataForTask(String? name) =>
      iconDataFor(name) ?? ActerIcons.list.data;

  static IconData iconDataForPin(String? name) =>
      iconDataFor(name) ?? ActerIcons.pin.data;

  //ENUM DECLARATION
  final IconData data;

  const ActerIcons(this.data);
}

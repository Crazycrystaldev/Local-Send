import 'package:localsend_app/model/device.dart';
import 'package:localsend_app/provider/last_devices.provider.dart';
import 'package:refena_flutter/refena_flutter.dart';
import 'package:test/test.dart';

void main() {
  test('Should add a device', () {
    final notifier = ReduxNotifier.test(
      redux: LastDevicesNotifier(),
    );

    expect(notifier.state, []);

    final device = _createDevice('123.123');
    notifier.dispatch(AddLastDeviceAction(device));

    expect(notifier.state, [device]);
  });

  test('Should remove the 5th device', () {
    final notifier = ReduxNotifier.test(
      redux: LastDevicesNotifier(),
    );

    notifier.dispatch(AddLastDeviceAction(_createDevice('1')));
    notifier.dispatch(AddLastDeviceAction(_createDevice('2')));
    notifier.dispatch(AddLastDeviceAction(_createDevice('3')));
    notifier.dispatch(AddLastDeviceAction(_createDevice('4')));
    notifier.dispatch(AddLastDeviceAction(_createDevice('5')));

    expect(notifier.state.length, 5);
    expect(notifier.state, [
      _createDevice('5'),
      _createDevice('4'),
      _createDevice('3'),
      _createDevice('2'),
      _createDevice('1'),
    ]);

    notifier.dispatch(AddLastDeviceAction(_createDevice('6')));

    expect(notifier.state.length, 5);
    expect(notifier.state, [
      _createDevice('6'),
      _createDevice('5'),
      _createDevice('4'),
      _createDevice('3'),
      _createDevice('2'), // 5th device removed
    ]);
  });
}

Device _createDevice(String ip) {
  return Device(
    ip: ip,
    version: '1',
    port: 123,
    https: true,
    fingerprint: '123',
    alias: 'A',
    deviceModel: 'A',
    deviceType: DeviceType.mobile,
    download: false,
  );
}

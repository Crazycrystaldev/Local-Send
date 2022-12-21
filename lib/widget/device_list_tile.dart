import 'package:flutter/material.dart';
import 'package:localsend_app/model/device.dart';
import 'package:localsend_app/util/ip_helper.dart';
import 'package:localsend_app/widget/device_bage.dart';

class DeviceListTile extends StatelessWidget {
  final Device device;
  final VoidCallback? onTap;

  const DeviceListTile({required this.device, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            children: [
              Icon(device.deviceType.icon, size: 46),
              const SizedBox(width: 15),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(device.alias, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 5),
                  Wrap(
                    runSpacing: 10,
                    spacing: 10,
                    children: [
                      DeviceBadge(
                        color: Theme.of(context).colorScheme.tertiaryContainer,
                        label: '#${device.ip.visualId}',
                      ),
                      if (device.deviceModel != null)
                        DeviceBadge(
                          color: Theme.of(context).colorScheme.tertiaryContainer,
                          label: device.deviceModel!,
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../firebase/firebase_bootstrap.dart';
import '../../i18n/app_localizations.dart';

class DevStatusBanner extends StatelessWidget {
  const DevStatusBanner({super.key, required this.status});

  final FirebaseBootstrapResult status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final connected = status.isReady;
    final strings = context.t;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: connected ? scheme.secondary : const Color(0xFF2D2B35),
      child: Row(
        children: [
          Icon(
            connected ? Icons.cloud_done : Icons.offline_bolt,
            color: Colors.white,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              connected
                  ? strings.firebaseReady(status.userId)
                  : strings.cloudServicesOffline,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

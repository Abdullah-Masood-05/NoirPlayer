package com.ryanheise.audioservice;

import android.content.Context;
import android.content.Intent;

public class MediaButtonReceiver extends androidx.media.session.MediaButtonReceiver {
    public static final String ACTION_NOTIFICATION_DELETE = "com.ryanheise.audioservice.intent.action.ACTION_NOTIFICATION_DELETE";

    @Override
    public void onReceive(Context context, Intent intent) {
        if (intent != null
                && ACTION_NOTIFICATION_DELETE.equals(intent.getAction())
                && AudioService.instance != null) {
            AudioService.instance.handleDeleteNotification();
            return;
        }
        // Noir Player patch: while the audio service is running, hand media
        // buttons straight to its session. The default path restarts the
        // service with startForegroundService, which Android 12+ may refuse
        // when the app is in the background (e.g. buttons pressed in the
        // OnePlus lock screen / expanded Media player), dropping the press.
        if (intent != null
                && Intent.ACTION_MEDIA_BUTTON.equals(intent.getAction())
                && AudioService.instance != null
                && AudioService.instance.handleMediaButtonIntent(intent)) {
            return;
        }
        super.onReceive(context, intent);
    }
}

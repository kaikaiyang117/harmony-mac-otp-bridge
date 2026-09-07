import { notificationExtensionSubscription } from '@kit.NotificationKit';
import { NotificationContent } from '../models/NotificationContent';

export class NotificationExtractor {
  extract(notificationInfo: notificationExtensionSubscription.NotificationInfo): NotificationContent {
    return {
      packageName: notificationInfo.bundleName,
      title: notificationInfo.content.title,
      text: notificationInfo.content.text
    };
  }
}

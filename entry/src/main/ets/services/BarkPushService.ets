import { BusinessError } from '@kit.BasicServicesKit';
import { http } from '@kit.NetworkKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { BarkConfig } from '../models/BarkConfig';

const DOMAIN = 0x0000;
const TAG = 'HarmonyOtpBridge';

export interface BarkPushMessage {
  title: string;
  body: string;
  group?: string;
}

export class BarkPushService {
  async push(config: BarkConfig, message: BarkPushMessage): Promise<void> {
    const serverUrl = this.normalizeServerUrl(config.serverUrl);
    const deviceKey = config.deviceKey.trim();
    if ((!serverUrl.startsWith('http://') && !serverUrl.startsWith('https://')) || deviceKey.length === 0) {
      hilog.error(DOMAIN, TAG, '[BARK_PUSH_FAILED] incomplete_config');
      throw new Error('Bark 配置不完整');
    }

    const request = http.createHttp();
    try {
      hilog.info(DOMAIN, TAG, '[BARK_PUSH_START] title=%{public}s', message.title);
      const response = await request.request(`${serverUrl}/push`, {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json; charset=utf-8'
        },
        extraData: JSON.stringify({
          device_key: deviceKey,
          title: message.title,
          body: message.body,
          group: message.group ?? 'OTP'
        }),
        connectTimeout: 5000,
        readTimeout: 5000
      });

      if (response.responseCode < 200 || response.responseCode > 299) {
        hilog.error(DOMAIN, TAG, '[BARK_PUSH_FAILED] http=%{public}d', response.responseCode);
        throw new Error(`HTTP ${response.responseCode}`);
      }

      hilog.info(DOMAIN, TAG, '[BARK_PUSH_SUCCESS] title=%{public}s', message.title);
    } catch (error) {
      const businessError = error as BusinessError;
      const errorMessage = (error as Error).message;
      hilog.error(
        DOMAIN,
        TAG,
        '[BARK_PUSH_FAILED] code=%{public}d message=%{public}s',
        businessError.code ?? 0,
        errorMessage
      );
      throw new Error(errorMessage);
    } finally {
      request.destroy();
    }
  }

  private normalizeServerUrl(serverUrl: string): string {
    let normalized = serverUrl.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}

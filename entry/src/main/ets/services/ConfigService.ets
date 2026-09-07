import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { BarkConfig } from '../models/BarkConfig';

const PREFERENCES_NAME = 'bark_config';

export class ConfigService {
  async loadBarkConfig(context: common.Context): Promise<BarkConfig> {
    try {
      const store = await preferences.getPreferences(context, PREFERENCES_NAME);
      const serverUrl = await store.get('serverUrl', '') as string;
      const deviceKey = await store.get('deviceKey', '') as string;
      const enabled = await store.get('enabled', true) as boolean;
      return {
        serverUrl,
        deviceKey,
        enabled
      };
    } catch (error) {
      throw new Error((error as Error).message);
    }
  }

  async saveBarkConfig(context: common.Context, config: BarkConfig): Promise<void> {
    try {
      const store = await preferences.getPreferences(context, PREFERENCES_NAME);
      await store.put('serverUrl', this.normalizeServerUrl(config.serverUrl));
      await store.put('deviceKey', config.deviceKey.trim());
      await store.put('enabled', config.enabled);
      await store.flush();
    } catch (error) {
      throw new Error((error as Error).message);
    }
  }

  isValid(config: BarkConfig): boolean {
    const serverUrl = this.normalizeServerUrl(config.serverUrl);
    const hasHttpScheme = serverUrl.startsWith('http://') || serverUrl.startsWith('https://');
    return hasHttpScheme && config.deviceKey.trim().length > 0;
  }

  normalizeServerUrl(serverUrl: string): string {
    let normalized = serverUrl.trim();
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
}

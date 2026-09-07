import { UIAbility, Want } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN = 0x0000;
const TAG = 'HarmonyOtpBridge';

export default class EntryAbility extends UIAbility {
  onWindowStageCreate(windowStage: window.WindowStage): void {
    windowStage.loadContent('pages/Index', (error) => {
      if (error.code) {
        hilog.error(DOMAIN, TAG, 'Failed to load content: %{public}s', JSON.stringify(error));
        return;
      }
      hilog.info(DOMAIN, TAG, 'Main page loaded');
    });
  }

  onWindowStageDestroy(): void {
    hilog.info(DOMAIN, TAG, 'Window stage destroyed');
  }

  onForeground(): void {
    hilog.info(DOMAIN, TAG, 'Application moved to foreground');
  }

  onBackground(): void {
    hilog.info(DOMAIN, TAG, 'Application moved to background');
  }
}


import { reactive } from 'vue';
import { recordedFetch, API_URL } from './api';

export const monthStatusService = reactive({
  monthlyStatus: new Map(),
  hasLoaded: false,

  async fetchMonthlyStatus(force = false) {
    if (this.hasLoaded && !force) {
      return;
    }
    try {
      const textContent = await recordedFetch('fetch monthly status', `${API_URL}/photos/monthly.txt`);
      this.parseMonthlyStatus(textContent);
      this.hasLoaded = true;
    } catch (error) {
      console.error('Failed to fetch monthly status:', error);
    }
  },

  parseMonthlyStatus(textContent) {
    this.monthlyStatus.clear();
    const lines = textContent.split('\n');
    lines.forEach(line => {
      const trimmedLine = line.trim();
      if (trimmedLine) {
        const [yyyymm, initials] = trimmedLine.split('=');
        if (yyyymm && initials) {
          this.monthlyStatus.set(yyyymm, initials);
        }
      }
    });
  },

  getInitialsForMonth(yyyymm) {
    return this.monthlyStatus.get(yyyymm) || '';
  },

  async toggleSignOff(yyyymm, initial, signedOff) {
    await this.fetchMonthlyStatus(true);
    let currentInitials = this.getInitialsForMonth(yyyymm);
    let newInitials;

    if (signedOff) {
      // Add initial if not already present
      if (!currentInitials.includes(initial)) {
        newInitials = (currentInitials + initial).split('').sort().join('');
      } else {
        newInitials = currentInitials;
      }
    } else {
      // Remove initial if present
      newInitials = currentInitials.replace(initial, '');
    }

    this.monthlyStatus.set(yyyymm, newInitials);

    // Convert map to file content string
    let fileContent = '';
    this.monthlyStatus.forEach((value, key) => {
      fileContent += `${key}=${value}\n`;
    });

    try {
      await recordedFetch('update monthly status', `${API_URL}/photos/monthlystatus.txt`, {
        method: 'POST',
        headers: {
          'Content-Type': 'text/plain',
        },
        body: fileContent,
      });
      console.log(`Successfully updated sign-off for ${yyyymm}`);
    } catch (error) {
      console.error('Failed to update monthly status:', error);
      // Revert local change if API call fails
      this.monthlyStatus.set(yyyymm, currentInitials);
    }
  },
});

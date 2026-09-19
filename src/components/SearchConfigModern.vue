<script setup lang="ts">
import { ref, onMounted, computed, watch } from 'vue';
import { type HealthStatus } from '@/api';
import type { DetectionSettings } from '@/types';
import { loadDetectionSettings, persistDetectionSettings } from '@/utils/linkDetection';

const props = defineProps<{
  backendHealth: HealthStatus | null;
}>();

// 网盘类型配置（带图标和颜色）
const diskTypes = [
  { id: 'baidu', name: '百度网盘', icon: '☁️', color: '#2932e1' },
  { id: 'aliyun', name: '阿里云盘', icon: '☁️', color: '#ff6a00' },
  { id: 'quark', name: '夸克网盘', icon: '⚡', color: '#1890ff' },
  { id: 'guangya', name: '光鸭云盘', icon: '🦆', color: '#0ea5a3' },
  { id: 'tianyi', name: '天翼云盘', icon: '☁️', color: '#0066cc' },
  { id: '115', name: '115网盘', icon: '📦', color: '#02a7f0' },
  { id: 'xunlei', name: '迅雷网盘', icon: '⚡', color: '#0090ff' },
  { id: 'uc', name: 'UC网盘', icon: '🌐', color: '#ff6600' },
  { id: 'mobile', name: '移动云盘', icon: '📱', color: '#0080ff' },
  { id: 'pikpak', name: 'PikPak', icon: '📦', color: '#ff4785' },
  { id: '123', name: '123云盘', icon: '💾', color: '#00b96b' },
  { id: 'magnet', name: '磁力链接', icon: '🧲', color: '#722ed1' },
  { id: 'ed2k', name: '电驴链接', icon: '🔗', color: '#fa8c16' }
];

const normalizeSavedDiskTypes = (savedTypes: string[]) => {
  const currentTypeIds = new Set(diskTypes.map((item) => item.id));
  return savedTypes.filter((type) => currentTypeIds.has(type));
};

const healthData = ref<HealthStatus | null>(null);
const loading = ref(true);
const error = ref<string | null>(null);

const selectedChannels = ref<string[]>([]);
const selectedPlugins = ref<string[]>([]);
const selectedDiskTypes = ref<string[]>([]);
const customChannels = ref<string[]>([]);

const newChannelInput = ref('');
const showChannelInput = ref(false);
const saveSuccess = ref(false);
const saveTimeout = ref<number | null>(null);
const showExportModal = ref(false);

const activeTab = ref<'channels' | 'plugins' | 'diskTypes' | 'detection'>('channels');
const detectionSettings = ref<DetectionSettings>(loadDetectionSettings());

const allChannels = computed(() => {
  if (!healthData.value) return [];
  return [...healthData.value.channels, ...customChannels.value];
});

const availablePlugins = computed(() => {
  if (!healthData.value) return [];
  return healthData.value.plugins || [];
});

const stats = computed(() => ({
  channels: selectedChannels.value.length,
  plugins: selectedPlugins.value.length,
  diskTypes: selectedDiskTypes.value.length
}));

// ---- 列表太长（默认 100+ 频道），加关键字过滤，避免只能靠滚动找 ----
const channelKeyword = ref('');
const pluginKeyword = ref('');

const visibleChannels = computed(() => {
  const kw = channelKeyword.value.trim().toLowerCase();
  const list = allChannels.value;
  if (!kw) return list;
  return list.filter((c) => c.toLowerCase().includes(kw));
});

const visiblePlugins = computed(() => {
  const kw = pluginKeyword.value.trim().toLowerCase();
  const list = availablePlugins.value;
  if (!kw) return list;
  return list.filter((p) => p.toLowerCase().includes(kw));
});

// 只保留「已选中的」列表（用于长列表下快速确认）
const showOnlySelected = ref(false);

const displayedChannels = computed(() =>
  showOnlySelected.value
    ? visibleChannels.value.filter((c) => selectedChannels.value.includes(c))
    : visibleChannels.value
);

const displayedPlugins = computed(() =>
  showOnlySelected.value
    ? visiblePlugins.value.filter((p) => selectedPlugins.value.includes(p))
    : visiblePlugins.value
);


const initHealth = () => {
  loading.value = true;
  error.value = null;
  if (props.backendHealth) {
    healthData.value = props.backendHealth;
    loading.value = false;
  } else {
    error.value = '获取状态失败';
    loading.value = false;
  }
};

watch(() => props.backendHealth, () => {
  initHealth();
}, { immediate: true });

const loadConfig = () => {
  try {
    const savedChannels = localStorage.getItem('pansou_channels');
    const savedPlugins = localStorage.getItem('pansou_plugins');
    const savedDiskTypes = localStorage.getItem('pansou_disk_types');
    const savedCustomChannels = localStorage.getItem('pansou_custom_channels');

    if (savedChannels) {
      selectedChannels.value = JSON.parse(savedChannels);
    } else if (healthData.value) {
      selectedChannels.value = [...healthData.value.channels];
    }

    if (savedPlugins) {
      selectedPlugins.value = JSON.parse(savedPlugins);
    } else if (healthData.value) {
      selectedPlugins.value = [...healthData.value.plugins];
    }

    if (savedDiskTypes) {
      selectedDiskTypes.value = normalizeSavedDiskTypes(JSON.parse(savedDiskTypes));
    } else {
      selectedDiskTypes.value = diskTypes.map(d => d.id);
    }

    if (savedCustomChannels) {
      customChannels.value = JSON.parse(savedCustomChannels);
    }
  } catch (err) {
    console.error('加载配置失败:', err);
  }
};

const saveConfig = () => {
  try {
    localStorage.setItem('pansou_channels', JSON.stringify(selectedChannels.value));
    localStorage.setItem('pansou_plugins', JSON.stringify(selectedPlugins.value));
    localStorage.setItem('pansou_disk_types', JSON.stringify(selectedDiskTypes.value));
    localStorage.setItem('pansou_custom_channels', JSON.stringify(customChannels.value));
    persistDetectionSettings(detectionSettings.value);

    saveSuccess.value = true;
    if (saveTimeout.value) {
      clearTimeout(saveTimeout.value);
    }
    saveTimeout.value = window.setTimeout(() => {
      saveSuccess.value = false;
    }, 2000);
    
    window.dispatchEvent(new CustomEvent('config:saved'));
  } catch (err) {
    console.error('保存配置失败:', err);
    alert('保存配置失败，请重试');
  }
};

const toggleChannel = (channel: string) => {
  const index = selectedChannels.value.indexOf(channel);
  if (index > -1) {
    selectedChannels.value.splice(index, 1);
  } else {
    selectedChannels.value.push(channel);
  }
};

const addChannel = () => {
  const channel = newChannelInput.value.trim();
  if (!channel) {
    alert('请输入频道名称');
    return;
  }
  if (allChannels.value.includes(channel)) {
    alert('频道已存在');
    return;
  }
  customChannels.value.push(channel);
  selectedChannels.value.push(channel);
  newChannelInput.value = '';
  showChannelInput.value = false;
};

const removeChannel = (channel: string) => {
  if (!customChannels.value.includes(channel)) return;
  if (confirm(`确定要删除频道"${channel}"吗？`)) {
    const customIndex = customChannels.value.indexOf(channel);
    if (customIndex > -1) customChannels.value.splice(customIndex, 1);
    const selectedIndex = selectedChannels.value.indexOf(channel);
    if (selectedIndex > -1) selectedChannels.value.splice(selectedIndex, 1);
  }
};

const toggleAllChannels = () => {
  if (selectedChannels.value.length === allChannels.value.length) {
    selectedChannels.value = [];
  } else {
    selectedChannels.value = [...allChannels.value];
  }
};

const togglePlugin = (plugin: string) => {
  const index = selectedPlugins.value.indexOf(plugin);
  if (index > -1) {
    selectedPlugins.value.splice(index, 1);
  } else {
    selectedPlugins.value.push(plugin);
  }
};

const toggleAllPlugins = () => {
  if (selectedPlugins.value.length === availablePlugins.value.length) {
    selectedPlugins.value = [];
  } else {
    selectedPlugins.value = [...availablePlugins.value];
  }
};

const toggleDiskType = (type: string) => {
  const index = selectedDiskTypes.value.indexOf(type);
  if (index > -1) {
    selectedDiskTypes.value.splice(index, 1);
  } else {
    selectedDiskTypes.value.push(type);
  }
};

const toggleAllDiskTypes = () => {
  if (selectedDiskTypes.value.length === diskTypes.length) {
    selectedDiskTypes.value = [];
  } else {
    selectedDiskTypes.value = diskTypes.map(d => d.id);
  }
};

const resetToDefault = () => {
  if (confirm('确定要重置为默认配置吗？这将清除所有自定义设置。')) {
    if (healthData.value) {
      selectedChannels.value = [...healthData.value.channels];
      selectedPlugins.value = [...healthData.value.plugins];
      selectedDiskTypes.value = diskTypes.map(d => d.id);
      customChannels.value = [];
      detectionSettings.value = { enabled: false };
      saveConfig();
    }
  }
};

const isCustomChannel = (channel: string) => {
  return customChannels.value.includes(channel);
};

const getExportData = () => {
  return {
    plugins: selectedPlugins.value.join(','),
    channels: selectedChannels.value.join(',')
  };
};

const openExportModal = () => {
  showExportModal.value = true;
};

const closeExportModal = () => {
  showExportModal.value = false;
};

const copyToClipboard = async (text: string, successMessage: string = '已复制！') => {
  try {
    if (navigator.clipboard && navigator.clipboard.writeText) {
      await navigator.clipboard.writeText(text);
      alert(successMessage);
      return true;
    }
    const textarea = document.createElement('textarea');
    textarea.value = text;
    textarea.style.position = 'fixed';
    textarea.style.opacity = '0';
    document.body.appendChild(textarea);
    textarea.select();
    const success = document.execCommand('copy');
    document.body.removeChild(textarea);
    if (success) alert(successMessage);
    return success;
  } catch (error) {
    console.error('复制失败:', error);
    return false;
  }
};

const copyPluginsConfig = async () => {
  const data = getExportData();
  const content = data.plugins ? `export ENABLED_PLUGINS=${data.plugins}` : 'export ENABLED_PLUGINS=';
  await copyToClipboard(content, '插件配置已复制！');
};

const copyChannelsConfig = async () => {
  const data = getExportData();
  const content = data.channels ? `export CHANNELS=${data.channels}` : 'export CHANNELS=';
  await copyToClipboard(content, 'TG频道配置已复制！');
};

onMounted(() => {
  initHealth();
  loadConfig();
  detectionSettings.value = loadDetectionSettings();
});
</script>

<template>
  <div class="modern-config">
    <!-- 顶部英雄区 -->
    <div class="hero-section">
      <div class="hero-content">
        <h1 class="hero-title">
          <span class="hero-icon">⚙️</span>
          搜索配置
        </h1>
        <p class="hero-subtitle">自定义你的搜索来源和结果类型</p>
      </div>
      
      <!-- 统计卡片 -->
      <div class="stats-grid">
        <div class="stat-card stat-channels">
          <div class="stat-icon">📡</div>
          <div class="stat-info">
            <div class="stat-value">{{ stats.channels }}</div>
            <div class="stat-label">TG频道</div>
          </div>
        </div>
        <div class="stat-card stat-plugins">
          <div class="stat-icon">🔌</div>
          <div class="stat-info">
            <div class="stat-value">{{ stats.plugins }}</div>
            <div class="stat-label">搜索插件</div>
          </div>
        </div>
        <div class="stat-card stat-disks">
          <div class="stat-icon">💾</div>
          <div class="stat-info">
            <div class="stat-value">{{ stats.diskTypes }}</div>
            <div class="stat-label">网盘类型</div>
          </div>
        </div>
      </div>
    </div>

    <div v-if="loading" class="loading-state">
      <div class="spinner"></div>
      <p>加载配置中...</p>
    </div>

    <div v-else-if="error" class="error-state">
      <div class="error-icon">❌</div>
      <h3>加载失败</h3>
      <p>{{ error }}</p>
      <button @click="initHealth" class="retry-btn">重试</button>
    </div>

    <div v-else class="config-main">
      <!-- 现代化Tab -->
      <div class="tab-nav">
        <button 
          v-for="tab in [
            { id: 'channels', icon: '📡', label: 'TG频道', count: allChannels.length },
            { id: 'plugins', icon: '🔌', label: '搜索插件', count: availablePlugins.length },
            { id: 'diskTypes', icon: '💾', label: '网盘类型', count: diskTypes.length },
            { id: 'detection', icon: '🔍', label: '链接检测', status: detectionSettings.enabled }
          ]"
          :key="tab.id"
          class="tab-btn"
          :class="{ active: activeTab === tab.id }"
          @click="activeTab = tab.id"
        >
          <span class="tab-icon">{{ tab.icon }}</span>
          <span class="tab-label">{{ tab.label }}</span>
          <span v-if="tab.count !== undefined" class="tab-badge">{{ tab.count }}</span>
          <span v-else-if="tab.status !== undefined" class="tab-status" :class="tab.status ? 'on' : 'off'">
            {{ tab.status ? '已开启' : '已关闭' }}
          </span>
        </button>
      </div>

      <!-- Tab内容 -->
      <div class="tab-content">
        <!-- 生效范围说明：后端没有任何写配置接口，这里改的是前端搜索范围 -->
        <div class="scope-note">
          <div class="scope-note-title">这里的设置作用于「之后的每一次搜索」</div>
          <div class="scope-note-body">
            勾选的频道 / 插件 / 网盘类型会保存到本机浏览器，搜索时作为
            <code>channels</code> / <code>plugins</code> / <code>cloud_types</code>
            参数发给后端。后端自身启用哪些插件由部署时的
            <code>ENABLED_PLUGINS</code> / <code>CHANNELS</code> 决定，
            需要改服务端就用下面「导出环境变量」复制到后端配置后重启。
          </div>
        </div>

        <!-- TG频道 -->
        <div v-show="activeTab === 'channels'" class="panel">
          <div class="panel-header">
            <div>
              <h3>TG频道配置</h3>
              <span class="count">已选 {{ selectedChannels.length }} / {{ allChannels.length }}</span>
            </div>
            <div class="actions">
              <button @click="toggleAllChannels" class="btn-secondary">
                {{ selectedChannels.length === allChannels.length ? '取消全选' : '全选' }}
              </button>
              <button @click="showChannelInput = !showChannelInput" class="btn-primary">
                ➕ 添加频道
              </button>
            </div>
          </div>

          <div class="panel-body">
            <div v-if="showChannelInput" class="input-box">
              <input
                v-model="newChannelInput"
                type="text"
                placeholder="输入TG频道名称"
                @keydown.enter="addChannel"
              />
              <button @click="addChannel" class="btn-ok">添加</button>
              <button @click="showChannelInput = false; newChannelInput = ''" class="btn-cancel">取消</button>
            </div>

            <div class="list-tools">
              <input v-model="channelKeyword" type="search" class="list-search" placeholder="按名称过滤频道" />
              <label class="list-toggle">
                <input type="checkbox" v-model="showOnlySelected" />
                <span>只看已选</span>
              </label>
              <span class="list-count">{{ displayedChannels.length }} / {{ allChannels.length }}</span>
            </div>

            <div class="card-grid">
              <div
                v-for="channel in displayedChannels"
                :key="channel"
                class="card"
                :class="{ selected: selectedChannels.includes(channel), custom: isCustomChannel(channel) }"
                @click="toggleChannel(channel)"
              >
                <div class="card-icon">📡</div>
                <div class="card-body">
                  <div class="card-name">{{ channel }}</div>
                  <div v-if="isCustomChannel(channel)" class="badge">自定义</div>
                </div>
                <div class="checkbox" :class="{ checked: selectedChannels.includes(channel) }">
                  <span v-if="selectedChannels.includes(channel)">✓</span>
                </div>
                <button v-if="isCustomChannel(channel)" @click.stop="removeChannel(channel)" class="del-btn">✕</button>
              </div>
            </div>
          </div>
        </div>

        <!-- 插件 -->
        <div v-show="activeTab === 'plugins'" class="panel">
          <div class="panel-header">
            <div>
              <h3>搜索插件配置</h3>
              <span class="count">已选 {{ selectedPlugins.length }} / {{ availablePlugins.length }}</span>
            </div>
            <div class="actions">
              <button @click="toggleAllPlugins" class="btn-secondary">
                {{ selectedPlugins.length === availablePlugins.length ? '取消全选' : '全选' }}
              </button>
            </div>
          </div>

          <div class="panel-body">
            <div class="list-tools">
              <input v-model="pluginKeyword" type="search" class="list-search" placeholder="按名称过滤插件" />
              <label class="list-toggle">
                <input type="checkbox" v-model="showOnlySelected" />
                <span>只看已选</span>
              </label>
              <span class="list-count">{{ displayedPlugins.length }} / {{ availablePlugins.length }}</span>
            </div>

            <div class="card-grid">
              <div
                v-for="plugin in displayedPlugins"
                :key="plugin"
                class="card"
                :class="{ selected: selectedPlugins.includes(plugin) }"
                @click="togglePlugin(plugin)"
              >
                <div class="card-icon">🔌</div>
                <div class="card-body">
                  <div class="card-name">{{ plugin }}</div>
                </div>
                <div class="checkbox" :class="{ checked: selectedPlugins.includes(plugin) }">
                  <span v-if="selectedPlugins.includes(plugin)">✓</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 网盘类型 -->
        <div v-show="activeTab === 'diskTypes'" class="panel">
          <div class="panel-header">
            <div>
              <h3>网盘类型配置</h3>
              <span class="count">已选 {{ selectedDiskTypes.length }} / {{ diskTypes.length }}</span>
            </div>
            <div class="actions">
              <button @click="toggleAllDiskTypes" class="btn-secondary">
                {{ selectedDiskTypes.length === diskTypes.length ? '取消全选' : '全选' }}
              </button>
            </div>
          </div>

          <div class="panel-body">
            <div class="card-grid disk-grid">
              <div
                v-for="disk in diskTypes"
                :key="disk.id"
                class="card disk-card"
                :class="{ selected: selectedDiskTypes.includes(disk.id) }"
                :style="{ '--color': disk.color }"
                @click="toggleDiskType(disk.id)"
              >
                <div class="card-icon">{{ disk.icon }}</div>
                <div class="card-body">
                  <div class="card-name">{{ disk.name }}</div>
                </div>
                <div class="checkbox" :class="{ checked: selectedDiskTypes.includes(disk.id) }">
                  <span v-if="selectedDiskTypes.includes(disk.id)">✓</span>
                </div>
              </div>
            </div>
          </div>
        </div>

        <!-- 检测 -->
        <div v-show="activeTab === 'detection'" class="panel">
          <div class="panel-header">
            <div><h3>链接检测设置</h3></div>
          </div>

          <div class="panel-body">
            <div class="detection-box">
              <div class="detection-left">
                <div class="detection-icon">🔍</div>
                <div>
                  <h4>自动检测当前可见链接</h4>
                  <p>仅检测当前网盘标签页中屏幕可见的结果</p>
                </div>
              </div>
              <label class="switch">
                <input v-model="detectionSettings.enabled" type="checkbox" />
                <span class="slider"></span>
              </label>
            </div>
          </div>
        </div>
      </div>

      <!-- 底部操作栏 -->
      <div class="action-bar">
        <button @click="openExportModal" class="btn-action">📤 导出配置</button>
        <button @click="resetToDefault" class="btn-action btn-reset">🔄 重置默认</button>
        <button @click="saveConfig" class="btn-action btn-save" :class="{ success: saveSuccess }">
          {{ saveSuccess ? '✓ 保存成功' : '💾 保存配置' }}
        </button>
      </div>
    </div>

    <!-- 导出模态框 -->
    <Teleport to="body">
      <Transition name="fade">
        <div v-if="showExportModal" class="modal" @click="closeExportModal">
          <div class="modal-box" @click.stop>
            <div class="modal-head">
              <h2>📤 导出配置</h2>
              <button @click="closeExportModal" class="close-btn">✕</button>
            </div>
            
            <div class="modal-content">
              <p>以下是您当前的配置信息，可以分别复制使用。</p>
              
              <div class="export-block">
                <div class="block-header">
                  <h3>🔌 搜索插件配置</h3>
                  <button @click="copyPluginsConfig" class="copy-btn">📋 复制</button>
                </div>
                <pre>{{ getExportData().plugins ? `export ENABLED_PLUGINS=${getExportData().plugins}` : 'export ENABLED_PLUGINS=' }}</pre>
              </div>
              
              <div class="export-block">
                <div class="block-header">
                  <h3>📡 TG频道配置</h3>
                  <button @click="copyChannelsConfig" class="copy-btn">📋 复制</button>
                </div>
                <pre>{{ getExportData().channels ? `export CHANNELS=${getExportData().channels}` : 'export CHANNELS=' }}</pre>
              </div>
            </div>
            
            <div class="modal-foot">
              <button @click="closeExportModal" class="btn-close">关闭</button>
            </div>
          </div>
        </div>
      </Transition>
    </Teleport>
  </div>
</template>

<style scoped>
.modern-config {
  max-width: 1400px;
  margin: 0 auto;
  padding: 2rem;
}

.hero-section {
  margin-bottom: 2rem;
}

.hero-content {
  margin-bottom: 1.5rem;
}

.hero-title {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  font-size: 2rem;
  font-weight: 700;
  margin: 0 0 0.5rem 0;
}

.hero-icon {
  font-size: 2.5rem;
}

.hero-subtitle {
  font-size: 1.1rem;
  color: hsl(var(--muted-foreground));
  margin: 0;
}

.stats-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.5rem;
  background: linear-gradient(135deg, hsl(var(--card)) 0%, hsl(var(--muted)/0.3) 100%);
  border: 2px solid hsl(var(--border));
  border-radius: 1rem;
  transition: all 0.3s;
  cursor: pointer;
}

.stat-card:hover {
  transform: translateY(-4px);
  box-shadow: 0 8px 24px rgba(0,0,0,0.12);
}

.stat-card.stat-channels { border-color: #3b82f6; }
.stat-card.stat-plugins { border-color: #8b5cf6; }
.stat-card.stat-disks { border-color: #10b981; }

.stat-icon {
  font-size: 2.5rem;
}

.stat-value {
  font-size: 2rem;
  font-weight: 700;
  line-height: 1;
}

.stat-label {
  font-size: 0.875rem;
  color: hsl(var(--muted-foreground));
  font-weight: 500;
}

.loading-state, .error-state {
  text-align: center;
  padding: 4rem 2rem;
}

.spinner {
  width: 3rem;
  height: 3rem;
  border: 4px solid hsl(var(--muted));
  border-top: 4px solid hsl(var(--primary));
  border-radius: 50%;
  animation: spin 1s linear infinite;
  margin: 0 auto 1rem;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.error-icon {
  font-size: 4rem;
  margin-bottom: 1rem;
}

.retry-btn {
  margin-top: 1rem;
  padding: 0.75rem 1.5rem;
  background: hsl(var(--destructive));
  color: white;
  border: none;
  border-radius: 0.5rem;
  cursor: pointer;
}

.tab-nav {
  display: flex;
  gap: 0.5rem;
  padding: 0.5rem;
  background: hsl(var(--muted)/0.3);
  border-radius: 1rem;
  margin-bottom: 1.5rem;
}

.tab-btn {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 0.875rem 1.25rem;
  background: transparent;
  border: none;
  border-radius: 0.75rem;
  cursor: pointer;
  transition: all 0.2s;
  color: hsl(var(--muted-foreground));
  font-weight: 500;
}

.tab-btn:hover {
  background: hsl(var(--background));
  color: hsl(var(--foreground));
}

.tab-btn.active {
  background: linear-gradient(135deg, hsl(var(--primary)) 0%, hsl(var(--primary)/0.8) 100%);
  color: white;
  box-shadow: 0 4px 12px hsl(var(--primary)/0.3);
}

.tab-icon {
  font-size: 1.25rem;
}

.tab-badge {
  min-width: 1.75rem;
  height: 1.75rem;
  padding: 0 0.5rem;
  display: inline-flex;
  align-items: center;
  justify-content: center;
  background: rgba(255,255,255,0.2);
  border-radius: 9999px;
  font-size: 0.8rem;
  font-weight: 600;
}

.tab-btn.active .tab-badge {
  background: white;
  color: hsl(var(--primary));
}

.tab-status {
  padding: 0.25rem 0.75rem;
  border-radius: 9999px;
  font-size: 0.75rem;
  font-weight: 600;
}

.tab-status.on {
  background: rgba(34,197,94,0.15);
  color: rgb(21,128,61);
}

.tab-status.off {
  background: hsl(var(--muted));
  color: hsl(var(--muted-foreground));
}

.panel {
  animation: fadeIn 0.3s;
}

@keyframes fadeIn {
  from { opacity: 0; transform: translateY(-10px); }
  to { opacity: 1; transform: translateY(0); }
}

.panel-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  background: hsl(var(--card));
  border: 2px solid hsl(var(--border));
  border-radius: 1rem 1rem 0 0;
}

.panel-header h3 {
  font-size: 1.25rem;
  font-weight: 600;
  margin: 0 1rem 0 0;
  display: inline;
}

.count {
  font-size: 0.875rem;
  color: hsl(var(--muted-foreground));
}

.actions {
  display: flex;
  gap: 0.75rem;
}

.btn-secondary, .btn-primary, .btn-ok, .btn-cancel {
  padding: 0.625rem 1.25rem;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  font-weight: 500;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-secondary {
  background: hsl(var(--background));
  border: 2px solid hsl(var(--border));
  color: hsl(var(--foreground));
}

.btn-secondary:hover {
  background: hsl(var(--accent));
  transform: scale(1.05);
}

.btn-primary {
  background: linear-gradient(135deg, hsl(var(--primary)) 0%, hsl(var(--primary)/0.8) 100%);
  color: white;
  border: 2px solid hsl(var(--primary));
}

.btn-primary:hover {
  transform: scale(1.05);
  box-shadow: 0 4px 12px hsl(var(--primary)/0.3);
}

.panel-body {
  padding: 1.5rem;
  background: hsl(var(--card));
  border: 2px solid hsl(var(--border));
  border-top: none;
  border-radius: 0 0 1rem 1rem;
  min-height: 300px;
}

.input-box {
  display: flex;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
  padding: 1rem;
  background: hsl(var(--muted)/0.3);
  border-radius: 0.75rem;
}

.input-box input {
  flex: 1;
  padding: 0.75rem 1rem;
  border: 2px solid hsl(var(--border));
  border-radius: 0.5rem;
  background: hsl(var(--background));
}

.input-box input:focus {
  outline: none;
  border-color: hsl(var(--primary));
}

.btn-ok {
  background: hsl(var(--primary));
  color: white;
  border: none;
}

.btn-cancel {
  background: hsl(var(--muted));
  border: none;
}

.card-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(280px, 1fr));
  gap: 1rem;
}

.disk-grid {
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
}

.card {
  position: relative;
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1.25rem;
  background: hsl(var(--background));
  border: 2px solid hsl(var(--border));
  border-radius: 0.75rem;
  cursor: pointer;
  transition: all 0.2s;
}

.card:hover {
  border-color: hsl(var(--primary)/0.5);
  transform: translateY(-2px);
  box-shadow: 0 4px 12px rgba(0,0,0,0.08);
}

.card.selected {
  background: linear-gradient(135deg, hsl(var(--primary)/0.08) 0%, hsl(var(--primary)/0.03) 100%);
  border-color: hsl(var(--primary));
  border-width: 3px;
}

.disk-card.selected {
  border-color: var(--color);
  background: linear-gradient(135deg, color-mix(in srgb, var(--color) 8%, transparent) 0%, transparent 100%);
}

.card-icon {
  font-size: 2rem;
  flex-shrink: 0;
}

.card-body {
  flex: 1;
  min-width: 0;
}

.card-name {
  font-size: 0.95rem;
  font-weight: 500;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.badge {
  display: inline-block;
  padding: 0.15rem 0.5rem;
  margin-top: 0.25rem;
  background: hsl(var(--primary)/0.15);
  color: hsl(var(--primary));
  border-radius: 0.25rem;
  font-size: 0.7rem;
  font-weight: 600;
}

.checkbox {
  width: 1.5rem;
  height: 1.5rem;
  border: 2px solid hsl(var(--border));
  border-radius: 0.375rem;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
  transition: all 0.2s;
}

.checkbox.checked {
  background: hsl(var(--primary));
  border-color: hsl(var(--primary));
  color: white;
}

.disk-card.selected .checkbox.checked {
  background: var(--color);
  border-color: var(--color);
}

.del-btn {
  position: absolute;
  top: 0.5rem;
  right: 0.5rem;
  width: 1.5rem;
  height: 1.5rem;
  background: hsl(var(--destructive));
  color: white;
  border: none;
  border-radius: 50%;
  cursor: pointer;
  opacity: 0;
  transition: all 0.2s;
}

.card:hover .del-btn {
  opacity: 1;
}

.detection-box {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 2rem;
  background: linear-gradient(135deg, hsl(var(--card)) 0%, hsl(var(--muted)/0.2) 100%);
  border: 2px solid hsl(var(--border));
  border-radius: 1rem;
}

.detection-left {
  display: flex;
  align-items: center;
  gap: 1.5rem;
  flex: 1;
}

.detection-icon {
  font-size: 3rem;
}

.detection-box h4 {
  font-size: 1.125rem;
  font-weight: 600;
  margin: 0 0 0.5rem 0;
}

.detection-box p {
  font-size: 0.875rem;
  color: hsl(var(--muted-foreground));
  margin: 0;
}

.switch {
  position: relative;
  width: 60px;
  height: 32px;
  cursor: pointer;
}

.switch input {
  opacity: 0;
  width: 0;
  height: 0;
}

.slider {
  position: absolute;
  inset: 0;
  background: hsl(var(--muted));
  border-radius: 9999px;
  transition: all 0.3s;
}

.slider::before {
  content: '';
  position: absolute;
  width: 24px;
  height: 24px;
  left: 4px;
  bottom: 4px;
  background: white;
  border-radius: 50%;
  transition: all 0.3s;
}

input:checked + .slider {
  background: hsl(var(--primary));
}

input:checked + .slider::before {
  transform: translateX(28px);
}

.action-bar {
  display: flex;
  gap: 1rem;
  justify-content: flex-end;
  margin-top: 2rem;
  padding: 1.5rem;
  background: hsl(var(--card));
  border: 2px solid hsl(var(--border));
  border-radius: 1rem;
}

.btn-action {
  padding: 0.875rem 1.75rem;
  border: 2px solid hsl(var(--border));
  border-radius: 0.75rem;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.2s;
  background: hsl(var(--background));
}

.btn-action:hover {
  transform: scale(1.05);
}

.btn-reset {
  background: hsl(var(--destructive)/0.1);
  color: hsl(var(--destructive));
  border-color: hsl(var(--destructive)/0.3);
}

.btn-reset:hover {
  background: hsl(var(--destructive));
  color: white;
}

.btn-save {
  background: linear-gradient(135deg, hsl(var(--primary)) 0%, hsl(var(--primary)/0.8) 100%);
  color: white;
  border-color: hsl(var(--primary));
}

.btn-save.success {
  background: linear-gradient(135deg, rgb(34,197,94) 0%, rgb(21,128,61) 100%);
}

.modal {
  position: fixed;
  inset: 0;
  z-index: 10000;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 1rem;
  background: rgba(0,0,0,0.6);
  backdrop-filter: blur(8px);
}

.modal-box {
  width: min(100%, 700px);
  max-height: 85vh;
  overflow-y: auto;
  background: hsl(var(--card));
  border: 2px solid hsl(var(--border));
  border-radius: 1.5rem;
  box-shadow: 0 24px 64px rgba(0,0,0,0.3);
}

.modal-head {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem 2rem;
  border-bottom: 2px solid hsl(var(--border));
}

.modal-head h2 {
  font-size: 1.5rem;
  font-weight: 700;
  margin: 0;
}

.close-btn {
  width: 2.5rem;
  height: 2.5rem;
  display: flex;
  align-items: center;
  justify-content: center;
  background: hsl(var(--muted));
  border: none;
  border-radius: 50%;
  font-size: 1.25rem;
  cursor: pointer;
  transition: all 0.2s;
}

.close-btn:hover {
  background: hsl(var(--destructive));
  color: white;
}

.modal-content {
  padding: 2rem;
}

.export-block {
  margin-bottom: 1.5rem;
}

.block-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.block-header h3 {
  font-size: 1.125rem;
  font-weight: 600;
  margin: 0;
}

.copy-btn {
  padding: 0.5rem 1rem;
  background: hsl(var(--primary));
  color: white;
  border: none;
  border-radius: 0.5rem;
  font-size: 0.875rem;
  cursor: pointer;
  transition: all 0.2s;
}

.copy-btn:hover {
  transform: scale(1.05);
}

.export-block pre {
  padding: 1rem;
  background: hsl(var(--muted)/0.3);
  border: 2px solid hsl(var(--border));
  border-radius: 0.5rem;
  font-family: monospace;
  font-size: 0.875rem;
  overflow-x: auto;
  margin: 0;
}

.modal-foot {
  padding: 1.5rem 2rem;
  border-top: 2px solid hsl(var(--border));
  text-align: right;
}

.btn-close {
  padding: 0.75rem 2rem;
  background: hsl(var(--muted));
  border: none;
  border-radius: 0.5rem;
  font-weight: 500;
  cursor: pointer;
}

.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s;
}

.fade-enter-from, .fade-leave-to {
  opacity: 0;
}

@media (max-width: 768px) {
  .modern-config {
    padding: 1rem;
  }

  .hero-title {
    font-size: 1.5rem;
  }

  .stats-grid {
    grid-template-columns: 1fr;
  }

  .tab-nav {
    flex-direction: column;
  }

  .panel-header {
    flex-direction: column;
    gap: 1rem;
  }

  .card-grid {
    grid-template-columns: 1fr;
  }

  .action-bar {
    flex-direction: column;
  }
}
/* 生效范围说明 */
.scope-note {
  margin: 0 0 1.25rem;
  padding: 0.85rem 1rem;
  border-radius: 0.75rem;
  border: 1px solid hsl(var(--primary) / 0.25);
  background: hsl(var(--primary) / 0.06);
}

.scope-note-title {
  font-size: 0.85rem;
  font-weight: 600;
  color: hsl(var(--foreground));
  margin-bottom: 0.3rem;
}

.scope-note-body {
  font-size: 0.78rem;
  line-height: 1.7;
  color: hsl(var(--muted-foreground));
}

.scope-note-body code {
  padding: 0.05rem 0.3rem;
  border-radius: 0.25rem;
  border: 1px solid hsl(var(--border));
  background: hsl(var(--muted));
  font-size: 0.72rem;
  color: hsl(var(--foreground));
}

/* 长列表工具栏 */
.list-tools {
  display: flex;
  align-items: center;
  gap: 0.6rem;
  margin-bottom: 0.75rem;
  flex-wrap: wrap;
}

.list-search {
  flex: 1 1 12rem;
  min-width: 8rem;
  padding: 0.45rem 0.7rem;
  font-size: 0.8rem;
  color: hsl(var(--foreground));
  background: hsl(var(--background));
  border: 1px solid hsl(var(--border));
  border-radius: 0.5rem;
  outline: none;
}

.list-search:focus { border-color: hsl(var(--primary)); }

.list-toggle {
  display: inline-flex;
  align-items: center;
  gap: 0.35rem;
  font-size: 0.78rem;
  color: hsl(var(--muted-foreground));
  cursor: pointer;
  user-select: none;
  white-space: nowrap;
}

.list-toggle input { accent-color: hsl(var(--primary)); cursor: pointer; }

.list-count {
  font-size: 0.75rem;
  color: hsl(var(--muted-foreground));
  font-variant-numeric: tabular-nums;
  white-space: nowrap;
}
</style>

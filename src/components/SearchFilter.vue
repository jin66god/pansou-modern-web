<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { getDiskTypeName } from '@/utils/diskTypes';

// Props
const props = defineProps<{
  mergedResults: Record<string, any[]>;
  hasSearched: boolean;
}>();

// Emits
const emit = defineEmits<{
  (e: 'filter-change', filters: FilterState): void;
}>();

// 筛选状态
interface FilterState {
  sources: string[];  // 'all' | 'telegram' | 'plugin'
  diskTypes: string[];
}

const selectedSources = ref<string[]>(['all']);
const selectedDiskTypes = ref<string[]>([]);

// 可用的网盘类型（从搜索结果中提取）
const availableDiskTypes = computed(() => {
  return Object.keys(props.mergedResults || {}).sort();
});

// 网盘类型显示名称映射
const diskTypeDisplayNames = computed(() => {
  const map: Record<string, string> = {};
  availableDiskTypes.value.forEach(type => {
    map[type] = getDiskTypeName(type);
  });
  return map;
});

// 网盘类型统计
const diskTypeStats = computed(() => {
  const stats: Record<string, number> = {};
  availableDiskTypes.value.forEach(type => {
    const items = props.mergedResults[type];
    stats[type] = Array.isArray(items) ? items.length : 0;
  });
  return stats;
});

// 切换数据源
const toggleSource = (source: string) => {
  if (source === 'all') {
    selectedSources.value = ['all'];
  } else {
    // 移除 'all'
    const allIndex = selectedSources.value.indexOf('all');
    if (allIndex > -1) {
      selectedSources.value.splice(allIndex, 1);
    }
    
    // 切换当前选项
    const index = selectedSources.value.indexOf(source);
    if (index > -1) {
      selectedSources.value.splice(index, 1);
    } else {
      selectedSources.value.push(source);
    }
    
    // 如果没有选中任何项，恢复 'all'
    if (selectedSources.value.length === 0) {
      selectedSources.value = ['all'];
    }
  }
  
  emitFilterChange();
};

// 切换网盘类型
const toggleDiskType = (diskType: string) => {
  const index = selectedDiskTypes.value.indexOf(diskType);
  if (index > -1) {
    selectedDiskTypes.value.splice(index, 1);
  } else {
    selectedDiskTypes.value.push(diskType);
  }
  
  emitFilterChange();
};

// 全选/取消全选网盘类型
const toggleAllDiskTypes = () => {
  if (selectedDiskTypes.value.length === availableDiskTypes.value.length) {
    selectedDiskTypes.value = [];
  } else {
    selectedDiskTypes.value = [...availableDiskTypes.value];
  }
  
  emitFilterChange();
};

// 触发筛选变更事件
const emitFilterChange = () => {
  emit('filter-change', {
    sources: selectedSources.value,
    diskTypes: selectedDiskTypes.value
  });
};

// 监听搜索结果变化，重置筛选
watch(() => props.mergedResults, () => {
  // 重置为默认状态
  selectedSources.value = ['all'];
  selectedDiskTypes.value = [];
  emitFilterChange();
}, { deep: true });
</script>

<template>
  <div class="search-filter" v-if="hasSearched">
    <!-- 搜索来源筛选 -->
    <div class="filter-section">
      <div class="section-header">
        <h3 class="section-title">搜题来源</h3>
      </div>
      <div class="filter-tabs">
        <button 
          class="filter-tab"
          :class="{ active: selectedSources.includes('all') }"
          @click="toggleSource('all')"
        >
          全部
        </button>
        <button 
          class="filter-tab"
          :class="{ active: selectedSources.includes('telegram') }"
          @click="toggleSource('telegram')"
        >
          Telegram
        </button>
        <button 
          class="filter-tab"
          :class="{ active: selectedSources.includes('plugin') }"
          @click="toggleSource('plugin')"
        >
          插件
        </button>
      </div>
    </div>

    <!-- 网盘类型筛选 -->
    <div class="filter-section" v-if="availableDiskTypes.length > 0">
      <div class="section-header">
        <h3 class="section-title">网盘类型</h3>
        <button 
          class="header-action"
          @click="toggleAllDiskTypes"
        >
          {{ selectedDiskTypes.length === availableDiskTypes.length ? '取消' : '全部' }}
        </button>
      </div>
      <div class="disk-type-grid">
        <button
          v-for="diskType in availableDiskTypes"
          :key="diskType"
          class="disk-type-card"
          :class="{ selected: selectedDiskTypes.includes(diskType) }"
          @click="toggleDiskType(diskType)"
        >
          <div class="disk-type-info">
            <span class="disk-type-name">{{ diskTypeDisplayNames[diskType] }}</span>
            <span class="disk-type-count">{{ diskTypeStats[diskType] }}</span>
          </div>
          <div class="disk-type-checkbox">
            <svg v-if="selectedDiskTypes.includes(diskType)" class="check-icon" viewBox="0 0 20 20" fill="currentColor">
              <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd" />
            </svg>
          </div>
        </button>
      </div>
    </div>
  </div>
</template>

<style scoped>
.search-filter {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
  padding: 1rem;
  background: hsl(var(--background));
  border-radius: 0.5rem;
  height: fit-content;
  position: sticky;
  top: 1rem;
}

/* 筛选区块 */
.filter-section {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.section-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.section-title {
  font-size: 0.95rem;
  font-weight: 600;
  color: hsl(var(--foreground));
  margin: 0;
}

.header-action {
  font-size: 0.8rem;
  color: hsl(var(--primary));
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 0.25rem 0.5rem;
  border-radius: 0.25rem;
  transition: all 0.2s ease;
}

.header-action:hover {
  background: hsl(var(--primary) / 0.1);
}

/* 数据源标签 */
.filter-tabs {
  display: flex;
  gap: 0.5rem;
}

.filter-tab {
  flex: 1;
  padding: 0.5rem 0.75rem;
  font-size: 0.85rem;
  font-weight: 500;
  background: hsl(var(--muted));
  color: hsl(var(--muted-foreground));
  border: 1px solid hsl(var(--border));
  border-radius: 0.375rem;
  cursor: pointer;
  transition: all 0.2s ease;
  white-space: nowrap;
}

.filter-tab:hover {
  background: hsl(var(--accent));
  color: hsl(var(--accent-foreground));
}

.filter-tab.active {
  background: hsl(var(--primary));
  color: hsl(var(--primary-foreground));
  border-color: hsl(var(--primary));
  font-weight: 600;
}

/* 网盘类型网格 */
.disk-type-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.5rem;
}

.disk-type-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 0.25rem;
  padding: 0.75rem 0.5rem;
  background: hsl(var(--card));
  border: 1.5px solid hsl(var(--border));
  border-radius: 0.5rem;
  cursor: pointer;
  transition: all 0.2s ease;
  position: relative;
  min-height: 4rem;
}

.disk-type-card:hover {
  border-color: hsl(var(--primary));
  background: hsl(var(--accent) / 0.5);
}

.disk-type-card.selected {
  background: hsl(var(--primary) / 0.1);
  border-color: hsl(var(--primary));
  border-width: 2px;
}

.disk-type-info {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
  width: 100%;
}

.disk-type-name {
  font-size: 0.85rem;
  font-weight: 500;
  color: hsl(var(--foreground));
  text-align: center;
}

.disk-type-count {
  font-size: 0.75rem;
  color: hsl(var(--muted-foreground));
  font-weight: 400;
}

.disk-type-checkbox {
  position: absolute;
  top: 0.25rem;
  right: 0.25rem;
  width: 1rem;
  height: 1rem;
  border-radius: 0.25rem;
  background: hsl(var(--background));
  border: 1.5px solid hsl(var(--border));
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s ease;
}

.disk-type-card.selected .disk-type-checkbox {
  background: hsl(var(--primary));
  border-color: hsl(var(--primary));
}

.check-icon {
  width: 0.75rem;
  height: 0.75rem;
  color: hsl(var(--primary-foreground));
}

/* 响应式 - 移动端 */
@media (max-width: 768px) {
  .search-filter {
    position: static;
    padding: 0.75rem;
  }
  
  .filter-tabs {
    flex-direction: row;
  }
  
  .disk-type-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>

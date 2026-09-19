<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import {
  getDiskTypeName,
  getDiskTypeFullName,
  getDiskTypeColor,
  getDiskTypeBadge,
  sortDiskTypesByCount
} from '@/utils/diskTypes';
import type { MergedResults, ResultItem } from '@/types';

export interface FilterState {
  sources: string[];   // 'telegram' | 'plugin'
  diskTypes: string[];
}

const props = defineProps<{
  mergedResults: MergedResults;
  rawResults?: ResultItem[];
  channels?: string[];
  plugins?: string[];
  hasSearched: boolean;
  loading?: boolean;
}>();

const emit = defineEmits<{
  (e: 'filter-change', filters: FilterState): void;
}>();

// ------- 状态 -------
const selectedSources = ref<string[]>([]);   // 空 = 全部来源
const selectedDiskTypes = ref<string[]>([]); // 空 = 全部网盘
const keyword = ref('');                     // 网盘类型搜索
const collapsed = ref(false);

// ------- 来源判定 -------
const channelSet = computed(() => new Set(props.channels || []));
const pluginSet = computed(() => new Set(props.plugins || []));

const sourceOfMerged = (item: any): 'telegram' | 'plugin' | 'unknown' => {
  const src = String(item?.source || '');
  if (!src) return 'unknown';
  if (channelSet.value.has(src)) return 'telegram';
  if (pluginSet.value.has(src)) return 'plugin';
  // 后端频道名通常是 @xxx 或纯英文；插件名是本站定义的英文标识
  return 'unknown';
};

const sourceOfRaw = (item: ResultItem): 'telegram' | 'plugin' | 'unknown' => {
  const ch = String(item?.channel || '');
  if (!ch) return 'unknown';
  if (channelSet.value.has(ch)) return 'telegram';
  if (pluginSet.value.has(ch)) return 'plugin';
  if (ch.startsWith('@')) return 'telegram';
  return 'plugin';
};

// ------- 统计（应用来源筛选后的即时数字） -------
const allMergedTypes = computed(() => Object.keys(props.mergedResults || {}));

// 来源过滤后仍然可见的 merged 结果
const mergedAfterSource = computed<MergedResults>(() => {
  const srcs = selectedSources.value;
  if (srcs.length === 0) return props.mergedResults || {};
  const out: MergedResults = {};
  for (const [type, items] of Object.entries(props.mergedResults || {})) {
    const kept = (items as any[]).filter((it) => srcs.includes(sourceOfMerged(it)));
    if (kept.length) out[type] = kept as any;
  }
  return out;
});

// 来源过滤后仍然可见的原始消息
const rawAfterSource = computed<ResultItem[]>(() => {
  const list = props.rawResults || [];
  const srcs = selectedSources.value;
  if (srcs.length === 0) return list;
  return list.filter((it) => srcs.includes(sourceOfRaw(it)));
});

// 每个网盘类型的条数（基于来源过滤后的数据，两个通道取较大值展示）
const typeCounts = computed<Record<string, number>>(() => {
  const counts: Record<string, number> = {};
  for (const [type, items] of Object.entries(mergedAfterSource.value)) {
    counts[type] = (counts[type] || 0) + (items as any[]).length;
  }
  for (const item of rawAfterSource.value) {
    for (const link of item.links || []) {
      const t = link.type || 'other';
      counts[t] = (counts[t] || 0) + 1;
    }
  }
  return counts;
});

// 排序后的网盘类型列表（只显示实际有结果的）
const orderedDiskTypes = computed(() => sortDiskTypesByCount(typeCounts.value));

// 搜索框过滤后的展示列表
const visibleDiskTypes = computed(() => {
  const kw = keyword.value.trim().toLowerCase();
  if (!kw) return orderedDiskTypes.value;
  return orderedDiskTypes.value.filter((t) =>
    `${t} ${getDiskTypeName(t)} ${getDiskTypeFullName(t)}`.toLowerCase().includes(kw)
  );
});

const totalRawCount = computed(() => rawAfterSource.value.length);

const sourceCounts = computed(() => {
  const mergedAll = Object.values(props.mergedResults || {}) as any[][];
  let tg = 0;
  let pl = 0;
  let unknown = 0;
  mergedAll.forEach((items) => {
    items.forEach((it) => {
      const s = sourceOfMerged(it);
      if (s === 'telegram') tg += 1;
      else if (s === 'plugin') pl += 1;
      else unknown += 1;
    });
  });
  // merged 里统计不到来源时，用原始消息兜底
  if (tg === 0 && pl === 0) {
    (props.rawResults || []).forEach((it) => {
      const s = sourceOfRaw(it);
      if (s === 'telegram') tg += 1;
      else if (s === 'plugin') pl += 1;
    });
  }
  return { tg, pl, unknown };
});

const allTypesSelected = computed(
  () => orderedDiskTypes.value.length > 0 &&
    selectedDiskTypes.value.length === orderedDiskTypes.value.length
);

const hasActiveFilter = computed(
  () => selectedSources.value.length > 0 || selectedDiskTypes.value.length > 0
);

// ------- 操作 -------
const emitChange = () => {
  emit('filter-change', {
    sources: [...selectedSources.value],
    diskTypes: [...selectedDiskTypes.value]
  });
};

const toggleSource = (source: 'telegram' | 'plugin') => {
  const idx = selectedSources.value.indexOf(source);
  if (idx > -1) selectedSources.value.splice(idx, 1);
  else selectedSources.value.push(source);
  // 来源变了，已选网盘可能已不存在，做一次收敛
  const valid = new Set(orderedDiskTypes.value);
  selectedDiskTypes.value = selectedDiskTypes.value.filter((t) => valid.has(t));
  emitChange();
};

const toggleDiskType = (type: string) => {
  const idx = selectedDiskTypes.value.indexOf(type);
  if (idx > -1) selectedDiskTypes.value.splice(idx, 1);
  else selectedDiskTypes.value.push(type);
  emitChange();
};

const selectAllDiskTypes = () => {
  selectedDiskTypes.value = allTypesSelected.value ? [] : [...orderedDiskTypes.value];
  emitChange();
};

const clearAll = () => {
  selectedSources.value = [];
  selectedDiskTypes.value = [];
  keyword.value = '';
  emitChange();
};

// 供模板使用：按名字移除已选来源（避免在模板里写 TS 类型断言）
const removeSource = (name: string) => {
  const idx = selectedSources.value.indexOf(name);
  if (idx > -1) selectedSources.value.splice(idx, 1);
  const valid = new Set(orderedDiskTypes.value);
  selectedDiskTypes.value = selectedDiskTypes.value.filter((t) => valid.has(t));
  emitChange();
};

const selectAllSources = () => {
  selectedSources.value = [];
  emitChange();
};

const isOnlyThisType = (type: string) => {
  return selectedDiskTypes.value.length === 1 && selectedDiskTypes.value[0] === type;
};

const onlyThisType = (type: string) => {
  selectedDiskTypes.value = isOnlyThisType(type) ? [] : [type];
  emitChange();
};

// 搜索结果整体变化（新一次搜索）时，只保留仍然有效的网盘选择
watch(
  () => props.mergedResults,
  () => {
    const valid = new Set(orderedDiskTypes.value);
    const next = selectedDiskTypes.value.filter((t) => valid.has(t));
    if (next.length !== selectedDiskTypes.value.length) {
      selectedDiskTypes.value = next;
      emitChange();
    }
  },
  { deep: false }
);
</script>

<template>
  <div class="filter-panel" :class="{ 'is-collapsed': collapsed }">
    <!-- 头部 -->
    <div class="filter-head">
      <div class="filter-head-title">
        <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path stroke-linecap="round" stroke-linejoin="round"
                d="M3 5h18M6 12h12M10 19h4" />
        </svg>
        <span>筛选结果</span>
        <span v-if="hasActiveFilter" class="filter-dot"></span>
      </div>
      <div class="filter-head-actions">
        <button v-if="hasActiveFilter" class="link-btn" @click="clearAll">清除</button>
        <button class="icon-btn mobile-only" :title="collapsed ? '展开筛选' : '收起筛选'"
                @click="collapsed = !collapsed">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path stroke-linecap="round" stroke-linejoin="round"
                  :d="collapsed ? 'M6 9l6 6 6-6' : 'M6 15l6-6 6 6'" />
          </svg>
        </button>
      </div>
    </div>

    <div class="filter-body">
      <!-- 数据来源 -->
      <section class="filter-section">
        <h4 class="filter-label">
          数据来源
          <span v-if="selectedSources.length" class="filter-label-tip">
            已选 {{ selectedSources.length }}
          </span>
        </h4>
        <div class="source-tabs">
          <button class="source-tab" :class="{ active: selectedSources.length === 0 }"
                  @click="selectAllSources()">
            全部
          </button>
          <button class="source-tab" :class="{ active: selectedSources.includes('telegram') }"
                  @click="toggleSource('telegram')">
            Telegram
            <em v-if="sourceCounts.tg">{{ sourceCounts.tg }}</em>
          </button>
          <button class="source-tab" :class="{ active: selectedSources.includes('plugin') }"
                  @click="toggleSource('plugin')">
            插件
            <em v-if="sourceCounts.pl">{{ sourceCounts.pl }}</em>
          </button>
        </div>
      </section>

      <!-- 网盘类型 -->
      <section class="filter-section" v-if="orderedDiskTypes.length">
        <h4 class="filter-label">
          网盘类型
          <button class="link-btn" @click="selectAllDiskTypes">
            {{ allTypesSelected ? '取消全选' : '全选' }}
          </button>
        </h4>

        <div class="disk-search" v-if="orderedDiskTypes.length > 6">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <circle cx="11" cy="11" r="7" />
            <path stroke-linecap="round" d="m20 20-3.5-3.5" />
          </svg>
          <input v-model="keyword" type="search" placeholder="搜索网盘类型" />
        </div>

        <ul class="disk-list">
          <li v-for="type in visibleDiskTypes" :key="type">
            <button class="disk-row"
                    :class="{ selected: selectedDiskTypes.includes(type) }"
                    @click="toggleDiskType(type)">
              <span class="disk-check" aria-hidden="true">
                <svg v-if="selectedDiskTypes.includes(type)" viewBox="0 0 20 20" fill="currentColor">
                  <path fill-rule="evenodd"
                        d="M16.7 5.3a1 1 0 010 1.4l-8 8a1 1 0 01-1.4 0l-4-4a1 1 0 111.4-1.4L8 12.6l7.3-7.3a1 1 0 011.4 0z"
                        clip-rule="evenodd" />
                </svg>
              </span>
              <span class="disk-badge" :style="{ background: getDiskTypeColor(type) }">
                {{ getDiskTypeBadge(type) }}
              </span>
              <span class="disk-name">{{ getDiskTypeName(type) }}</span>
              <span class="disk-count">{{ typeCounts[type] }}</span>
              <span class="disk-only" :class="{ on: isOnlyThisType(type) }"
                    @click.stop="onlyThisType(type)">仅此</span>
            </button>
          </li>
          <li v-if="!visibleDiskTypes.length" class="disk-empty">
            没有匹配「{{ keyword }}」的网盘类型
          </li>
        </ul>
      </section>

      <div v-else-if="hasSearched && !loading" class="filter-empty">
        本次搜索没有可筛选的网盘结果
      </div>

      <!-- 当前生效的筛选 -->
      <section class="filter-section filter-summary" v-if="hasActiveFilter">
        <h4 class="filter-label">当前筛选</h4>
        <div class="chips">
          <span v-for="s in selectedSources" :key="'s-' + s" class="chip chip-source">
            {{ s === 'telegram' ? 'Telegram' : '插件' }}
            <button @click="removeSource(s)">×</button>
          </span>
          <span v-for="t in selectedDiskTypes" :key="'t-' + t" class="chip">
            {{ getDiskTypeName(t) }}
            <button @click="toggleDiskType(t)">×</button>
          </span>
        </div>
      </section>
    </div>
  </div>
</template>

<style scoped>
.filter-panel {
  position: sticky;
  top: 5.5rem;
  display: flex;
  flex-direction: column;
  background: hsl(var(--card));
  border: 1px solid hsl(var(--border));
  border-radius: 0.875rem;
  box-shadow: 0 1px 2px hsl(var(--foreground) / 0.04);
  overflow: hidden;
}

.filter-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 0.5rem;
  padding: 0.85rem 1rem;
  border-bottom: 1px solid hsl(var(--border));
  background: linear-gradient(180deg, hsl(var(--muted) / 0.55), transparent);
}

.filter-head-title {
  display: flex;
  align-items: center;
  gap: 0.45rem;
  font-size: 0.9rem;
  font-weight: 600;
  color: hsl(var(--foreground));
}

.filter-head-title svg { width: 1.05rem; height: 1.05rem; opacity: 0.7; }

.filter-dot {
  width: 0.4rem; height: 0.4rem; border-radius: 999px;
  background: hsl(var(--primary));
}

.filter-head-actions { display: flex; align-items: center; gap: 0.25rem; }

.filter-body {
  display: flex;
  flex-direction: column;
  gap: 1.1rem;
  padding: 1rem;
}

.filter-panel.is-collapsed .filter-body { display: none; }

.filter-section { display: flex; flex-direction: column; gap: 0.6rem; }

.filter-label {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin: 0;
  font-size: 0.78rem;
  font-weight: 600;
  letter-spacing: 0.02em;
  color: hsl(var(--muted-foreground));
}

.filter-label-tip { font-weight: 400; color: hsl(var(--primary)); }

.link-btn {
  background: none; border: none; padding: 0;
  font-size: 0.75rem; color: hsl(var(--primary)); cursor: pointer;
}
.link-btn:hover { text-decoration: underline; }

.icon-btn {
  background: none; border: none; cursor: pointer; padding: 0.15rem;
  color: hsl(var(--muted-foreground)); display: inline-flex;
}
.icon-btn svg { width: 1rem; height: 1rem; }
.mobile-only { display: none; }

/* 来源 */
.source-tabs {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 0.3rem;
  padding: 0.25rem;
  background: hsl(var(--muted) / 0.7);
  border-radius: 0.6rem;
}

.source-tab {
  display: inline-flex; align-items: center; justify-content: center; gap: 0.3rem;
  padding: 0.4rem 0.35rem;
  font-size: 0.78rem; font-weight: 500;
  color: hsl(var(--muted-foreground));
  background: transparent; border: none; border-radius: 0.45rem;
  cursor: pointer; transition: all 0.18s ease;
}

.source-tab em {
  font-style: normal; font-size: 0.65rem; opacity: 0.75;
}

.source-tab:hover { color: hsl(var(--foreground)); }

.source-tab.active {
  background: hsl(var(--card));
  color: hsl(var(--foreground));
  box-shadow: 0 1px 3px hsl(var(--foreground) / 0.12);
}

/* 网盘搜索框 */
.disk-search {
  display: flex; align-items: center; gap: 0.4rem;
  padding: 0.35rem 0.55rem;
  border: 1px solid hsl(var(--border));
  border-radius: 0.5rem;
  background: hsl(var(--background));
}
.disk-search svg { width: 0.9rem; height: 0.9rem; color: hsl(var(--muted-foreground)); flex: none; }
.disk-search input {
  width: 100%; border: none; outline: none; background: transparent;
  font-size: 0.8rem; color: hsl(var(--foreground));
}

/* 网盘列表 */
.disk-list { list-style: none; margin: 0; padding: 0; display: flex; flex-direction: column; gap: 0.2rem; }
.disk-list { max-height: 22rem; overflow-y: auto; }

.disk-row {
  width: 100%;
  display: flex; align-items: center; gap: 0.5rem;
  padding: 0.42rem 0.5rem;
  background: transparent; border: 1px solid transparent; border-radius: 0.5rem;
  cursor: pointer; text-align: left; transition: all 0.15s ease;
}

.disk-row:hover { background: hsl(var(--accent) / 0.6); border-color: hsl(var(--border)); }
.disk-row.selected { background: hsl(var(--primary) / 0.08); border-color: hsl(var(--primary) / 0.35); }

.disk-check {
  flex: none; width: 0.95rem; height: 0.95rem; border-radius: 0.25rem;
  border: 1.5px solid hsl(var(--border));
  display: inline-flex; align-items: center; justify-content: center;
  color: hsl(var(--primary-foreground));
}
.disk-check svg { width: 0.65rem; height: 0.65rem; }
.disk-row.selected .disk-check { background: hsl(var(--primary)); border-color: hsl(var(--primary)); }

.disk-badge {
  flex: none; width: 1.15rem; height: 1.15rem; border-radius: 0.35rem;
  display: inline-flex; align-items: center; justify-content: center;
  font-size: 0.62rem; font-weight: 700; color: #fff;
}

.disk-name {
  flex: 1; font-size: 0.82rem; color: hsl(var(--foreground));
  white-space: nowrap; overflow: hidden; text-overflow: ellipsis;
}

.disk-count {
  flex: none; font-size: 0.72rem; color: hsl(var(--muted-foreground));
  font-variant-numeric: tabular-nums;
}

.disk-only {
  flex: none; font-size: 0.68rem; padding: 0.1rem 0.3rem; border-radius: 0.3rem;
  color: hsl(var(--muted-foreground)); border: 1px solid transparent; opacity: 0;
  transition: opacity 0.15s ease;
}
.disk-row:hover .disk-only { opacity: 1; border-color: hsl(var(--border)); }
.disk-only.on { opacity: 1; color: hsl(var(--primary)); border-color: hsl(var(--primary) / 0.4); }

.disk-empty, .filter-empty {
  font-size: 0.78rem; color: hsl(var(--muted-foreground)); padding: 0.5rem 0.25rem;
}

/* 已选胶囊 */
.filter-summary { border-top: 1px dashed hsl(var(--border)); padding-top: 0.85rem; }
.chips { display: flex; flex-wrap: wrap; gap: 0.3rem; }

.chip {
  display: inline-flex; align-items: center; gap: 0.25rem;
  padding: 0.16rem 0.3rem 0.16rem 0.5rem;
  font-size: 0.72rem;
  background: hsl(var(--primary) / 0.1);
  color: hsl(var(--primary));
  border: 1px solid hsl(var(--primary) / 0.25);
  border-radius: 999px;
}
.chip-source { background: hsl(var(--muted)); color: hsl(var(--foreground)); border-color: hsl(var(--border)); }
.chip button {
  background: none; border: none; cursor: pointer; line-height: 1;
  font-size: 0.85rem; color: inherit; opacity: 0.6; padding: 0 0.1rem;
}
.chip button:hover { opacity: 1; }

/* 窄屏：变成可折叠卡片 */
@media (max-width: 1023px) {
  .filter-panel { position: static; }
  .mobile-only { display: inline-flex; }
  .disk-list { max-height: 15rem; }
}
</style>
// 网盘类型元数据：中文名、短名、色相、排序工具

// 短名（列表/胶囊里用，保持与旧版一致）
export const diskTypeMap: Record<string, string> = {
  baidu: '百度',
  aliyun: '阿里',
  quark: '夸克',
  uc: 'UC',
  '115': '115',
  '123': '123',
  xunlei: '迅雷',
  tianyi: '天翼',
  mobile: '移动',
  pikpak: 'PikPak',
  guangya: '光鸭',
  magnet: '磁力',
  ed2k: '电驴',
  other: '其他'
};

// 全名（设置页、筛选面板里用）
export const diskTypeFullMap: Record<string, string> = {
  baidu: '百度网盘',
  aliyun: '阿里云盘',
  quark: '夸克网盘',
  uc: 'UC 网盘',
  '115': '115 网盘',
  '123': '123 网盘',
  xunlei: '迅雷网盘',
  tianyi: '天翼云盘',
  mobile: '移动云盘',
  pikpak: 'PikPak',
  guangya: '光鸭云盘',
  magnet: '磁力链接',
  ed2k: '电驴链接',
  other: '其他来源'
};

// 每个网盘一个色相，用于色条/图标背景，纯装饰
export const diskTypeColorMap: Record<string, string> = {
  baidu: '#2b6cff',
  aliyun: '#ff6a00',
  quark: '#3a7afe',
  uc: '#1fa2ff',
  '115': '#20b26c',
  '123': '#4b8bf5',
  xunlei: '#1e6fff',
  tianyi: '#e2352b',
  mobile: '#12b7a8',
  pikpak: '#7d5cff',
  guangya: '#f5a524',
  magnet: '#8b5cf6',
  ed2k: '#64748b',
  other: '#94a3b8'
};

// 获取网盘类型的中文短名
export const getDiskTypeName = (type: string): string => {
  return diskTypeMap[type] || type;
};

// 获取网盘类型的中文全名
export const getDiskTypeFullName = (type: string): string => {
  return diskTypeFullMap[type] || diskTypeMap[type] || type;
};

export const getDiskTypeColor = (type: string): string => {
  return diskTypeColorMap[type] || '#94a3b8';
};

// 生成网盘图标用的字母缩写：百度->百，磁力->磁，PikPak->P
export const getDiskTypeBadge = (type: string): string => {
  const name = getDiskTypeName(type);
  if (!name) return '?';
  return /^[a-zA-Z]/.test(name) ? name[0].toUpperCase() : name[0];
};

// 按「结果多的在前」排序，未知类型排最后
export const sortDiskTypesByCount = (counts: Record<string, number>): string[] => {
  return Object.keys(counts)
    .filter((key) => (counts[key] || 0) > 0)
    .sort((a, b) => {
      const diff = (counts[b] || 0) - (counts[a] || 0);
      if (diff !== 0) return diff;
      const known = (diskTypeMap[a] ? 0 : 1) - (diskTypeMap[b] ? 0 : 1);
      if (known !== 0) return known;
      return a.localeCompare(b);
    });
};

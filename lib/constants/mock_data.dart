import '../models/types.dart';

/// Top 10 menu items for MarkerView: price, total sales, total orders (for marketing strategy).
final mockMenuItems = <MenuItem>[
  MenuItem(id: '1', name: 'Bulgogi', price: 450, totalSales: 892500, totalOrders: 1983),
  MenuItem(id: '2', name: 'Kimchi Stew', price: 380, totalSales: 684000, totalOrders: 1800),
  MenuItem(id: '3', name: 'Bibimbap', price: 420, totalSales: 630000, totalOrders: 1500),
  MenuItem(id: '4', name: 'Tteokbokki', price: 280, totalSales: 504000, totalOrders: 1800),
  MenuItem(id: '5', name: 'Japchae', price: 350, totalSales: 455000, totalOrders: 1300),
  MenuItem(id: '6', name: 'Samgyeopsal', price: 520, totalSales: 624000, totalOrders: 1200),
  MenuItem(id: '7', name: 'Gimbap', price: 220, totalSales: 396000, totalOrders: 1800),
  MenuItem(id: '8', name: 'Galbi', price: 680, totalSales: 476000, totalOrders: 700),
  MenuItem(id: '9', name: 'Jjajangmyeon', price: 320, totalSales: 384000, totalOrders: 1200),
  MenuItem(id: '10', name: 'Naengmyeon', price: 400, totalSales: 360000, totalOrders: 900),
];

/// Mock "ongoing games" repurposed as restaurant branches: account = branch name, table = branch code, gameType = service type, buyIn = sales, cashOut = expenses, status = Open/Settling(Closing).
/// Branch names from stat cards: ESSOM, 김형제, 블루문, 다래정, 금호반점, 신규.
final mockOngoingGames = <OngoingGame>[
  OngoingGame(id: '1', account: 'ESSOM', buyIn: 144307900, cashOut: 28861580, table: 'BR-01', gameType: 'Dine-in', status: 'Active'),
  OngoingGame(id: '2', account: '김형제', buyIn: 7113730, cashOut: 1422746, table: 'BR-02', gameType: 'Dine-in', status: 'Active'),
  OngoingGame(id: '3', account: '블루문', buyIn: 151421630, cashOut: 30284326, table: 'BR-03', gameType: 'Dine-in', status: 'Active'),
  OngoingGame(id: '4', account: '다래정', buyIn: 3886576, cashOut: 777315, table: 'BR-04', gameType: 'Takeout', status: 'Settling'),
  OngoingGame(id: '5', account: '금호반점', buyIn: 148194476, cashOut: 29638895, table: 'BR-05', gameType: 'Dine-in', status: 'Active'),
  OngoingGame(id: '6', account: '신규', buyIn: 3227154, cashOut: 0, table: 'BR-06', gameType: 'Delivery', status: 'Active'),
];

final mockDailySettlement = <SettlementData>[
  SettlementData(date: 'Mon', numGames: 12, buyIn: 1200000, rolling: 4500000, winLoss: 350000, commission: 45000, expenses: 12000),
  SettlementData(date: 'Tue', numGames: 18, buyIn: 2100000, rolling: 6200000, winLoss: -120000, commission: 62000, expenses: 15000),
  SettlementData(date: 'Wed', numGames: 15, buyIn: 1800000, rolling: 5800000, winLoss: 450000, commission: 58000, expenses: 13500),
  SettlementData(date: 'Thu', numGames: 22, buyIn: 3200000, rolling: 8900000, winLoss: 890000, commission: 89000, expenses: 22000),
  SettlementData(date: 'Fri', numGames: 28, buyIn: 4500000, rolling: 12000000, winLoss: -540000, commission: 120000, expenses: 31000),
  SettlementData(date: 'Sat', numGames: 35, buyIn: 6200000, rolling: 18500000, winLoss: 1200000, commission: 185000, expenses: 45000),
  SettlementData(date: 'Sun', numGames: 30, buyIn: 5500000, rolling: 15200000, winLoss: 780000, commission: 152000, expenses: 38000),
];

/// Monthly settlement (date = month label). 7 months sample for MonthlyView charts.
final mockMonthlySettlement = <SettlementData>[
  SettlementData(date: 'Jan', numGames: 420, buyIn: 38500000, rolling: 142000000, winLoss: 12500000, commission: 1420000, expenses: 380000),
  SettlementData(date: 'Feb', numGames: 380, buyIn: 35200000, rolling: 128000000, winLoss: 9800000, commission: 1280000, expenses: 320000),
  SettlementData(date: 'Mar', numGames: 455, buyIn: 41800000, rolling: 158000000, winLoss: -2100000, commission: 1580000, expenses: 410000),
  SettlementData(date: 'Apr', numGames: 440, buyIn: 40100000, rolling: 148000000, winLoss: 15200000, commission: 1480000, expenses: 395000),
  SettlementData(date: 'May', numGames: 490, buyIn: 45200000, rolling: 168000000, winLoss: 18800000, commission: 1680000, expenses: 445000),
  SettlementData(date: 'Jun', numGames: 465, buyIn: 42800000, rolling: 155000000, winLoss: 11200000, commission: 1550000, expenses: 420000),
  SettlementData(date: 'Jul', numGames: 510, buyIn: 47500000, rolling: 175000000, winLoss: 22100000, commission: 1750000, expenses: 468000),
];

final mockMarkers = <MarkerEntry>[
  MarkerEntry(guest: 'Golden Dragon Agency', agent: 'John Smith (VIP-88)', balance: 1500000, limit: 2000000, lastUpdate: '10:45 AM'),
  MarkerEntry(guest: 'Silver Tiger Agency', agent: 'Jane Doe (VIP-12)', balance: 800000, limit: 1000000, lastUpdate: '11:20 AM'),
  MarkerEntry(guest: 'Phoenix Agency', agent: 'Chen Wei (VIP-45)', balance: 4200000, limit: 5000000, lastUpdate: '09:15 AM'),
  MarkerEntry(guest: 'Jade Emperor Agency', agent: 'Sarah Connor (VIP-01)', balance: 250000, limit: 500000, lastUpdate: '12:01 PM'),
  MarkerEntry(guest: 'Infinity Agency', agent: 'Bruce Wayne (VIP-BAT)', balance: 12000000, limit: 15000000, lastUpdate: '11:55 AM'),
];

final mockRanking = <RankingItem>[
  RankingItem(name: 'Agent Golden Dragon', rolling: 45000000, winnings: 3200000, losses: 1500000, commission: 450000, rank: 1),
  RankingItem(name: 'VIP Phoenix-01', rolling: 32000000, winnings: 1800000, losses: 2100000, commission: 320000, rank: 2),
  RankingItem(name: 'Agent Silver Tiger', rolling: 28000000, winnings: 2500000, losses: 900000, commission: 280000, rank: 3),
  RankingItem(name: 'VIP Jade Emperor', rolling: 25000000, winnings: 1200000, losses: 400000, commission: 250000, rank: 4),
  RankingItem(name: 'VIP Iron Fist', rolling: 19000000, winnings: 900000, losses: 1200000, commission: 190000, rank: 5),
];

/// Expense categories for RankingView (expenses list). Sample from design: 당월/전월/증감.
final mockExpenseCategories = <ExpenseCategoryItem>[
  ExpenseCategoryItem(rank: 1, name: '야채류', categoryId: 'INF397', currentMonth: 3390000, previousMonth: 112000000, change: 1620000),
  ExpenseCategoryItem(rank: 2, name: '고기류', categoryId: 'INF540', currentMonth: -8840000, previousMonth: 65100000, change: 944000),
  ExpenseCategoryItem(rank: 3, name: '인건비', categoryId: 'INF123', currentMonth: 3150000, previousMonth: 46400000, change: 672000),
  ExpenseCategoryItem(rank: 4, name: '주류', categoryId: 'INF400', currentMonth: 1930000, previousMonth: 42700000, change: 619000),
  ExpenseCategoryItem(rank: 5, name: '음료', categoryId: 'INF318', currentMonth: 608000, previousMonth: 25600000, change: 371000),
  ExpenseCategoryItem(rank: 6, name: '세금', categoryId: 'INF500', currentMonth: 1430000, previousMonth: 21200000, change: 307000),
  ExpenseCategoryItem(rank: 7, name: '공과금', categoryId: 'INF333', currentMonth: 4740000, previousMonth: 21100000, change: 305000),
];

final mockNotifications = <NotificationItem>[
  NotificationItem(id: 1, title: 'Large Order', message: 'Main Branch received a catering order for ₱45,000 — confirm by 2 PM.', time: '2 mins ago', type: 'urgent'),
  NotificationItem(id: 2, title: 'Daily Summary Ready', message: 'Today\'s sales summary for all branches has been generated.', time: '15 mins ago', type: 'success'),
  NotificationItem(id: 3, title: 'Low Stock Alert', message: '김치찌개 ingredients at Mall Branch are below reorder level.', time: '1 hour ago', type: 'warning'),
  NotificationItem(id: 4, title: 'New Review', message: 'A customer left a 5-star review for 금호반점.', time: '3 hours ago', type: 'info'),
];

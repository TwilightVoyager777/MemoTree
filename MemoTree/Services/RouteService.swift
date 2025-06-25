//
//  RouteService.swift
//  MemoTree
//
//  Created by 橡皮擦 on 2025/5/29.
//

import Foundation
import Combine
import CoreLocation
import CoreML

// MARK: - 路线服务
class RouteService: ObservableObject {
    static let shared = RouteService()
    
    @Published var routes: [Route] = []
    @Published var featuredRoutes: [Route] = []
    @Published var popularRoutes: [Route] = []
    @Published var nearbyRoutes: [Route] = []
    @Published var isLoading = false
    
    private let networkService = NetworkService.shared
    var cancellables = Set<AnyCancellable>()
    
    private init() {
        // 添加基本的模拟路线数据（第二步测试）
        setupMockRoutes()
    }
    
    // MARK: - 添加基本模拟数据
    private func setupMockRoutes() {
        let mockRoutes = [
            // 西湖经典路线
            Route(
                id: 1,
                name: "西湖十景漫步",
                description: "沿着西湖环线漫步，欣赏断桥残雪、苏堤春晓、三潭印月等经典十景。这条路线是杭州最经典的旅游线路，适合慢慢品味江南风韵，感受历史文化底蕴。春天柳絮飞舞，夏天荷花盛开，秋天桂花飘香，冬天雪景如画。",
                creator: AuthService.shared.getUserById(2), // 摄影爱好者
                startLatitude: 30.2652,
                startLongitude: 120.1432,
                endLatitude: 30.2489,
                endLongitude: 120.1428,
                startAddress: "断桥",
                endAddress: "雷峰塔",
                distance: 5.2,
                estimatedDuration: 120,
                difficulty: .easy,
                tags: [.photography, .history, .sightseeing],
                routePoints: [
                    RoutePoint(
                        id: 1,
                        latitude: 30.2652,
                        longitude: 120.1432,
                        name: "断桥残雪",
                        description: "西湖十景之一，冬日雪景最为美丽",
                        imageUrl: "https://picsum.photos/300/200?random=101",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 2,
                        latitude: 30.2634,
                        longitude: 120.1425,
                        name: "白堤",
                        description: "唐代诗人白居易主持修建，春天桃柳满堤",
                        imageUrl: "https://picsum.photos/300/200?random=102",
                        pointType: .viewpoint,
                        order: 2
                    ),
                    RoutePoint(
                        id: 3,
                        latitude: 30.2571,
                        longitude: 120.1339,
                        name: "苏堤春晓",
                        description: "西湖十景之首，苏东坡主持修建",
                        imageUrl: "https://picsum.photos/300/200?random=103",
                        pointType: .viewpoint,
                        order: 3
                    ),
                    RoutePoint(
                        id: 4,
                        latitude: 30.2489,
                        longitude: 120.1428,
                        name: "雷峰塔",
                        description: "西湖标志性建筑，夕阳西下时最美",
                        imageUrl: "https://picsum.photos/300/200?random=104",
                        pointType: .end,
                        order: 4
                    )
                ],
                coverImage: "route_cover_1",
                views: 2180,
                likes: 189,
                collections: 234,
                completions: 167,
                averageRating: 4.8,
                ratingCount: 156,
                status: .published,
                isPublic: true,
                isFeatured: true,
                createdAt: "2024-01-01T10:30:00Z",
                updatedAt: "2024-01-01T10:30:00Z"
            ),
            
            // 灵隐寺文化路线
            Route(
                id: 2,
                name: "灵隐禅境之旅",
                description: "探访千年古刹灵隐寺，感受佛教文化的庄严与宁静。沿途欣赏飞来峰石窟造像，体验杭州深厚的宗教文化底蕴。这里是济公活佛的出家地，香火旺盛，是祈福求愿的圣地。",
                creator: AuthService.shared.getUserById(4), // 历史文化爱好者
                startLatitude: 30.2408,
                startLongitude: 120.0985,
                endLatitude: 30.2445,
                endLongitude: 120.0942,
                startAddress: "飞来峰",
                endAddress: "灵隐寺",
                distance: 2.3,
                estimatedDuration: 90,
                difficulty: .medium,
                tags: [.culture, .history, .temple],
                routePoints: [
                    RoutePoint(
                        id: 5,
                        latitude: 30.2408,
                        longitude: 120.0985,
                        name: "飞来峰",
                        description: "奇石嶙峋，石窟造像众多",
                        imageUrl: "https://picsum.photos/300/200?random=105",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 6,
                        latitude: 30.2425,
                        longitude: 120.0963,
                        name: "冷泉亭",
                        description: "苏东坡题词的千年古亭",
                        imageUrl: "https://picsum.photos/300/200?random=106",
                        pointType: .viewpoint,
                        order: 2
                    ),
                    RoutePoint(
                        id: 7,
                        latitude: 30.2445,
                        longitude: 120.0942,
                        name: "灵隐寺",
                        description: "江南著名古刹，济公出家地",
                        imageUrl: "https://picsum.photos/300/200?random=107",
                        pointType: .end,
                        order: 3
                    )
                ],
                coverImage: "route_cover_2",
                views: 1450,
                likes: 98,
                collections: 156,
                completions: 89,
                averageRating: 4.6,
                ratingCount: 89,
                status: .published,
                isPublic: true,
                isFeatured: false,
                createdAt: "2024-01-02T14:20:00Z",
                updatedAt: "2024-01-02T14:20:00Z"
            ),
            
            // 宋城主题路线
            Route(
                id: 3,
                name: "宋城穿越之旅",
                description: "体验南宋文化主题公园，观看《宋城千古情》大型演出，感受'给我一天，还你千年'的时空穿越体验。这里有丰富的宋代文化展示，精彩的民俗表演，是了解杭州历史文化的最佳去处。",
                creator: AuthService.shared.getUserById(3), // 美食达人
                startLatitude: 30.1980,
                startLongitude: 120.1124,
                endLatitude: 30.1995,
                endLongitude: 120.1145,
                startAddress: "宋城景区入口",
                endAddress: "千古情剧院",
                distance: 1.8,
                estimatedDuration: 180,
                difficulty: .easy,
                tags: [.culture, .entertainment, .family],
                routePoints: [
                    RoutePoint(
                        id: 8,
                        latitude: 30.1980,
                        longitude: 120.1124,
                        name: "宋城门楼",
                        description: "仿宋建筑，古朴典雅的入口",
                        imageUrl: "https://picsum.photos/300/200?random=108",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 9,
                        latitude: 30.1985,
                        longitude: 120.1135,
                        name: "清明上河图馆",
                        description: "3D立体展示北宋繁华景象",
                        imageUrl: "https://picsum.photos/300/200?random=109",
                        pointType: .viewpoint,
                        order: 2
                    ),
                    RoutePoint(
                        id: 10,
                        latitude: 30.1990,
                        longitude: 120.1140,
                        name: "宋城美食街",
                        description: "品尝传统杭帮菜和小吃",
                        imageUrl: "https://picsum.photos/300/200?random=110",
                        pointType: .food,
                        order: 3
                    ),
                    RoutePoint(
                        id: 11,
                        latitude: 30.1995,
                        longitude: 120.1145,
                        name: "千古情剧院",
                        description: "大型歌舞表演《宋城千古情》",
                        imageUrl: "https://picsum.photos/300/200?random=111",
                        pointType: .end,
                        order: 4
                    )
                ],
                coverImage: "route_cover_3",
                views: 1680,
                likes: 145,
                collections: 189,
                completions: 112,
                averageRating: 4.7,
                ratingCount: 112,
                status: .published,
                isPublic: true,
                isFeatured: true,
                createdAt: "2024-01-03T09:15:00Z",
                updatedAt: "2024-01-03T09:15:00Z"
            ),
            
            // 钱塘江沿岸路线
            Route(
                id: 4,
                name: "钱塘江夜景骑行",
                description: "沿着钱塘江畔骑行，欣赏杭州现代化城市天际线。夜晚时分华灯初上，江景与城市灯光交相辉映，是摄影爱好者的天堂。路线平坦易行，适合休闲骑行和夜景拍摄。",
                creator: AuthService.shared.getUserById(2), // 摄影爱好者
                startLatitude: 30.2084,
                startLongitude: 120.2103,
                endLatitude: 30.1876,
                endLongitude: 120.1954,
                startAddress: "钱江新城",
                endAddress: "奥体中心",
                distance: 8.5,
                estimatedDuration: 90,
                difficulty: .medium,
                tags: [.cycling, .photography, .nightview],
                routePoints: [
                    RoutePoint(
                        id: 12,
                        latitude: 30.2084,
                        longitude: 120.2103,
                        name: "钱江新城CBD",
                        description: "现代化商务区，高楼林立",
                        imageUrl: "https://picsum.photos/300/200?random=112",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 13,
                        latitude: 30.1980,
                        longitude: 120.2028,
                        name: "钱塘江大桥",
                        description: "横跨钱塘江的现代大桥",
                        imageUrl: "https://picsum.photos/300/200?random=113",
                        pointType: .viewpoint,
                        order: 2
                    ),
                    RoutePoint(
                        id: 14,
                        latitude: 30.1876,
                        longitude: 120.1954,
                        name: "杭州奥体中心",
                        description: "亚运会主会场，建筑造型独特",
                        imageUrl: "https://picsum.photos/300/200?random=114",
                        pointType: .end,
                        order: 3
                    )
                ],
                coverImage: "route_cover_4",
                views: 980,
                likes: 78,
                collections: 89,
                completions: 45,
                averageRating: 4.5,
                ratingCount: 45,
                status: .published,
                isPublic: true,
                isFeatured: false,
                createdAt: "2024-01-04T19:30:00Z",
                updatedAt: "2024-01-04T19:30:00Z"
            ),
            
            // 新增路线 5: 千岛湖环湖徒步
            Route(
                id: 5,
                name: "千岛湖环湖徒步",
                description: "千岛湖是杭州最美的自然景观之一，环湖徒步可以欣赏湖光山色，呼吸清新空气。这条路线沿着湖岸线设计，途经多个观景台和休息点，是户外爱好者的首选路线。",
                creator: AuthService.shared.getUserById(1), // 城市探索者
                startLatitude: 29.6052,
                startLongitude: 119.0347,
                endLatitude: 29.6089,
                endLongitude: 119.0421,
                startAddress: "千岛湖旅游码头",
                endAddress: "梅峰观景台",
                distance: 12.3,
                estimatedDuration: 240,
                difficulty: .hard,
                tags: [.nature, .photography, .solo],
                routePoints: [
                    RoutePoint(
                        id: 15,
                        latitude: 29.6052,
                        longitude: 119.0347,
                        name: "千岛湖旅游码头",
                        description: "千岛湖的主要入口，可乘船游览",
                        imageUrl: "https://picsum.photos/300/200?random=115",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 16,
                        latitude: 29.6067,
                        longitude: 119.0378,
                        name: "龙山岛",
                        description: "湖中小岛，景色优美",
                        imageUrl: "https://picsum.photos/300/200?random=116",
                        pointType: .viewpoint,
                        order: 2
                    ),
                    RoutePoint(
                        id: 17,
                        latitude: 29.6078,
                        longitude: 119.0395,
                        name: "环湖栈道",
                        description: "沿湖而建的木制栈道",
                        imageUrl: "https://picsum.photos/300/200?random=117",
                        pointType: .rest,
                        order: 3
                    ),
                    RoutePoint(
                        id: 18,
                        latitude: 29.6089,
                        longitude: 119.0421,
                        name: "梅峰观景台",
                        description: "千岛湖最佳观景点，可俯瞰全景",
                        imageUrl: "https://picsum.photos/300/200?random=118",
                        pointType: .end,
                        order: 4
                    )
                ],
                coverImage: "route_cover_5",
                views: 1234,
                likes: 156,
                collections: 89,
                completions: 67,
                averageRating: 4.9,
                ratingCount: 78,
                status: .published,
                isPublic: true,
                isFeatured: true,
                createdAt: "2024-01-05T08:00:00Z",
                updatedAt: "2024-01-05T08:00:00Z"
            ),
            
            // 新增路线 6: 河坊街美食探店
            Route(
                id: 6,
                name: "河坊街美食探店",
                description: "河坊街是杭州最有名的历史文化街区，这里汇聚了众多老字号和特色小吃。跟着这条路线，品尝正宗的杭帮菜和传统点心，感受老杭州的市井风情。",
                creator: AuthService.shared.getUserById(3), // 美食达人
                startLatitude: 30.2467,
                startLongitude: 120.1695,
                endLatitude: 30.2453,
                endLongitude: 120.1734,
                startAddress: "河坊街入口",
                endAddress: "吴山广场",
                distance: 1.2,
                estimatedDuration: 150,
                difficulty: .easy,
                tags: [.food, .history, .shopping],
                routePoints: [
                    RoutePoint(
                        id: 19,
                        latitude: 30.2467,
                        longitude: 120.1695,
                        name: "河坊街牌坊",
                        description: "河坊街的标志性入口",
                        imageUrl: "https://picsum.photos/300/200?random=119",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 20,
                        latitude: 30.2463,
                        longitude: 120.1705,
                        name: "知味观",
                        description: "百年老字号，杭州小笼包发源地",
                        imageUrl: "https://picsum.photos/300/200?random=120",
                        pointType: .food,
                        order: 2
                    ),
                    RoutePoint(
                        id: 21,
                        latitude: 30.2459,
                        longitude: 120.1715,
                        name: "胡庆余堂",
                        description: "中华老字号药店，建筑精美",
                        imageUrl: "https://picsum.photos/300/200?random=121",
                        pointType: .historic,
                        order: 3
                    ),
                    RoutePoint(
                        id: 22,
                        latitude: 30.2455,
                        longitude: 120.1725,
                        name: "王星记扇庄",
                        description: "传统手工折扇制作",
                        imageUrl: "https://picsum.photos/300/200?random=122",
                        pointType: .shop,
                        order: 4
                    ),
                    RoutePoint(
                        id: 23,
                        latitude: 30.2453,
                        longitude: 120.1734,
                        name: "吴山广场",
                        description: "河坊街终点，可俯瞰西湖",
                        imageUrl: "https://picsum.photos/300/200?random=123",
                        pointType: .end,
                        order: 5
                    )
                ],
                coverImage: "route_cover_6",
                views: 892,
                likes: 234,
                collections: 178,
                completions: 189,
                averageRating: 4.7,
                ratingCount: 123,
                status: .published,
                isPublic: true,
                isFeatured: false,
                createdAt: "2024-01-06T12:30:00Z",
                updatedAt: "2024-01-06T12:30:00Z"
            ),
            
            // 新增路线 7: 九溪十八涧森林漫步
            Route(
                id: 7,
                name: "九溪十八涧森林漫步",
                description: "九溪十八涧是杭州最清幽的自然景区，山泉潺潺，林木葱郁。这条路线沿着溪流而上，穿越茂密的森林，是逃离城市喧嚣的绝佳选择。适合情侣约会和亲子出游。",
                creator: AuthService.shared.getUserById(2), // 摄影爱好者
                startLatitude: 30.2156,
                startLongitude: 120.1289,
                endLatitude: 30.2089,
                endLongitude: 120.1234,
                startAddress: "九溪烟树",
                endAddress: "十八涧尽头",
                distance: 3.5,
                estimatedDuration: 95,
                difficulty: .medium,
                tags: [.nature, .couple, .family],
                routePoints: [
                    RoutePoint(
                        id: 24,
                        latitude: 30.2156,
                        longitude: 120.1289,
                        name: "九溪烟树",
                        description: "西湖新十景之一，溪水九折",
                        imageUrl: "https://picsum.photos/300/200?random=124",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 25,
                        latitude: 30.2134,
                        longitude: 120.1267,
                        name: "龙井村",
                        description: "著名茶村，可品尝正宗龙井茶",
                        imageUrl: "https://picsum.photos/300/200?random=125",
                        pointType: .rest,
                        order: 2
                    ),
                    RoutePoint(
                        id: 26,
                        latitude: 30.2112,
                        longitude: 120.1245,
                        name: "理安寺遗址",
                        description: "古寺遗址，历史悠久",
                        imageUrl: "https://picsum.photos/300/200?random=126",
                        pointType: .historic,
                        order: 3
                    ),
                    RoutePoint(
                        id: 27,
                        latitude: 30.2089,
                        longitude: 120.1234,
                        name: "十八涧尽头",
                        description: "深山幽谷，泉水叮咚",
                        imageUrl: "https://picsum.photos/300/200?random=127",
                        pointType: .end,
                        order: 4
                    )
                ],
                coverImage: "route_cover_7",
                views: 1567,
                likes: 298,
                collections: 156,
                completions: 134,
                averageRating: 4.8,
                ratingCount: 167,
                status: .published,
                isPublic: true,
                isFeatured: true,
                createdAt: "2024-01-07T16:45:00Z",
                updatedAt: "2024-01-07T16:45:00Z"
            ),
            
            // 新增路线 8: 良渚文化村艺术之旅
            Route(
                id: 8,
                name: "良渚文化村艺术之旅",
                description: "良渚文化村是杭州的文化艺术高地，这里有众多美术馆、艺术工作室和文创空间。这条路线带你探索现代艺术与传统文化的完美融合，是艺术爱好者的必去之地。",
                creator: AuthService.shared.getUserById(4), // 历史文化爱好者
                startLatitude: 30.3789,
                startLongitude: 120.0234,
                endLatitude: 30.3823,
                endLongitude: 120.0289,
                startAddress: "良渚博物院",
                endAddress: "大屋顶美术馆",
                distance: 2.8,
                estimatedDuration: 180,
                difficulty: .easy,
                tags: [.art, .culture, .modern],
                routePoints: [
                    RoutePoint(
                        id: 28,
                        latitude: 30.3789,
                        longitude: 120.0234,
                        name: "良渚博物院",
                        description: "展示良渚文化的现代化博物馆",
                        imageUrl: "https://picsum.photos/300/200?random=128",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 29,
                        latitude: 30.3801,
                        longitude: 120.0256,
                        name: "文化艺术中心",
                        description: "举办各类文化展览和演出",
                        imageUrl: "https://picsum.photos/300/200?random=129",
                        pointType: .viewpoint,
                        order: 2
                    ),
                    RoutePoint(
                        id: 30,
                        latitude: 30.3812,
                        longitude: 120.0273,
                        name: "艺术家工作室群",
                        description: "众多艺术家的创作空间",
                        imageUrl: "https://picsum.photos/300/200?random=130",
                        pointType: .viewpoint,
                        order: 3
                    ),
                    RoutePoint(
                        id: 31,
                        latitude: 30.3823,
                        longitude: 120.0289,
                        name: "大屋顶美术馆",
                        description: "建筑设计独特的当代美术馆",
                        imageUrl: "https://picsum.photos/300/200?random=131",
                        pointType: .end,
                        order: 4
                    )
                ],
                coverImage: "route_cover_8",
                views: 756,
                likes: 89,
                collections: 123,
                completions: 78,
                averageRating: 4.6,
                ratingCount: 56,
                status: .published,
                isPublic: true,
                isFeatured: false,
                createdAt: "2024-01-08T10:15:00Z",
                updatedAt: "2024-01-08T10:15:00Z"
            ),
            
            // 新增路线 9: 西溪湿地观鸟之旅
            Route(
                id: 9,
                name: "西溪湿地观鸟之旅",
                description: "西溪国家湿地公园是杭州的'城市之肾'，这里生态环境优美，是众多鸟类的栖息地。这条路线专为观鸟爱好者设计，可以观察到白鹭、翠鸟等多种珍稀鸟类。",
                creator: AuthService.shared.getUserById(1), // 城市探索者
                startLatitude: 30.2678,
                startLongitude: 120.0567,
                endLatitude: 30.2734,
                endLongitude: 120.0623,
                startAddress: "西溪湿地东区入口",
                endAddress: "观鸟亭",
                distance: 4.6,
                estimatedDuration: 135,
                difficulty: .easy,
                tags: [.nature, .photography, .solo],
                routePoints: [
                    RoutePoint(
                        id: 32,
                        latitude: 30.2678,
                        longitude: 120.0567,
                        name: "湿地入口",
                        description: "西溪湿地的主要入口",
                        imageUrl: "https://picsum.photos/300/200?random=132",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 33,
                        latitude: 30.2695,
                        longitude: 120.0584,
                        name: "烟水渔庄",
                        description: "传统江南水乡建筑群",
                        imageUrl: "https://picsum.photos/300/200?random=133",
                        pointType: .viewpoint,
                        order: 2
                    ),
                    RoutePoint(
                        id: 34,
                        latitude: 30.2712,
                        longitude: 120.0601,
                        name: "秋雪庵",
                        description: "古朴的茶室，可品茶休息",
                        imageUrl: "https://picsum.photos/300/200?random=134",
                        pointType: .rest,
                        order: 3
                    ),
                    RoutePoint(
                        id: 35,
                        latitude: 30.2734,
                        longitude: 120.0623,
                        name: "观鸟亭",
                        description: "最佳观鸟点，配备望远镜",
                        imageUrl: "https://picsum.photos/300/200?random=135",
                        pointType: .end,
                        order: 4
                    )
                ],
                coverImage: "route_cover_9",
                views: 1123,
                likes: 167,
                collections: 89,
                completions: 98,
                averageRating: 4.7,
                ratingCount: 89,
                status: .published,
                isPublic: true,
                isFeatured: false,
                createdAt: "2024-01-09T07:30:00Z",
                updatedAt: "2024-01-09T07:30:00Z"
            ),
            
            // 新增路线 10: 径山寺禅修体验
            Route(
                id: 10,
                name: "径山寺禅修体验",
                description: "径山寺是中国茶道的发源地，也是重要的禅宗道场。这条路线不仅可以参观古刹，还可以体验茶道文化和禅修文化，是身心放松的绝佳选择。适合想要静心的朋友。",
                creator: AuthService.shared.getUserById(4), // 历史文化爱好者
                startLatitude: 30.4234,
                startLongitude: 119.9123,
                endLatitude: 30.4289,
                endLongitude: 119.9178,
                startAddress: "径山竹茶园",
                endAddress: "径山寺",
                distance: 3.2,
                estimatedDuration: 120,
                difficulty: .medium,
                tags: [.temple, .culture, .solo],
                routePoints: [
                    RoutePoint(
                        id: 36,
                        latitude: 30.4234,
                        longitude: 119.9123,
                        name: "径山竹茶园",
                        description: "径山茶的原产地，竹林茶园",
                        imageUrl: "https://picsum.photos/300/200?random=136",
                        pointType: .start,
                        order: 1
                    ),
                    RoutePoint(
                        id: 37,
                        latitude: 30.4256,
                        longitude: 119.9145,
                        name: "茶道文化馆",
                        description: "展示中国茶道历史文化",
                        imageUrl: "https://picsum.photos/300/200?random=137",
                        pointType: .viewpoint,
                        order: 2
                    ),
                    RoutePoint(
                        id: 38,
                        latitude: 30.4273,
                        longitude: 119.9162,
                        name: "径山古道",
                        description: "通往径山寺的古代石径",
                        imageUrl: "https://picsum.photos/300/200?random=138",
                        pointType: .waypoint,
                        order: 3
                    ),
                    RoutePoint(
                        id: 39,
                        latitude: 30.4289,
                        longitude: 119.9178,
                        name: "径山寺",
                        description: "千年古刹，禅茶文化发源地",
                        imageUrl: "https://picsum.photos/300/200?random=139",
                        pointType: .end,
                        order: 4
                    )
                ],
                coverImage: "route_cover_10",
                views: 654,
                likes: 78,
                collections: 67,
                completions: 56,
                averageRating: 4.9,
                ratingCount: 45,
                status: .published,
                isPublic: true,
                isFeatured: true,
                createdAt: "2024-01-10T06:00:00Z",
                updatedAt: "2024-01-10T06:00:00Z"
            )
        ]
        
        self.routes = mockRoutes
        
        // 更新分类数据
        self.featuredRoutes = mockRoutes.filter { $0.isFeatured }
        self.popularRoutes = mockRoutes.sorted { $0.views > $1.views }
        self.nearbyRoutes = mockRoutes // 所有路线都显示为附近路线
    }
    
    // 创建基本的路线点数据
    private func createBasicRoutePoints() -> [RoutePoint] {
        return [
            RoutePoint(
                id: 1,
                latitude: 31.2304,
                longitude: 121.4737,
                name: "外滩1号",
                description: "起点 - 外滩观景台",
                imageUrl: "https://picsum.photos/300/200?random=10",
                pointType: .start,
                order: 0
            ),
            RoutePoint(
                id: 2,
                latitude: 31.2350,
                longitude: 121.4780,
                name: "南京东路口",
                description: "途经 - 南京东路与外滩交汇处",
                imageUrl: nil,
                pointType: .waypoint,
                order: 1
            ),
            RoutePoint(
                id: 3,
                latitude: 31.2420,
                longitude: 121.4850,
                name: "外白渡桥",
                description: "终点 - 历史悠久的钢结构桥梁",
                imageUrl: "https://picsum.photos/300/200?random=11",
                pointType: .end,
                order: 2
            )
        ]
    }
    
    // MARK: - 公共方法
    
    // 获取所有路线
    func fetchAllRoutes() -> AnyPublisher<[Route], NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                promise(.success(self.routes))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 获取精选路线
    func fetchFeaturedRoutes() -> AnyPublisher<[Route], NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                promise(.success(self.featuredRoutes))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 获取热门路线
    func fetchPopularRoutes() -> AnyPublisher<[Route], NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                promise(.success(self.popularRoutes))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 获取附近路线
    func fetchNearbyRoutes(location: CLLocationCoordinate2D, radius: Double = 5.0) -> AnyPublisher<[Route], NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                promise(.success(self.nearbyRoutes))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 搜索路线
    func searchRoutes(query: String, filters: RouteFilters? = nil) -> AnyPublisher<[Route], NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                let filteredRoutes = self.routes.filter { route in
                    route.name.localizedCaseInsensitiveContains(query) ||
                    (route.description?.localizedCaseInsensitiveContains(query) ?? false) ||
                    route.tags.contains { $0.displayName.localizedCaseInsensitiveContains(query) }
                }
                promise(.success(filteredRoutes))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 获取路线详情
    func fetchRouteDetail(id: Int64) -> AnyPublisher<Route, NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let route = self.routes.first(where: { $0.id == id }) {
                    promise(.success(route))
                } else {
                    promise(.failure(.notFound))
                }
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 点赞路线
    func likeRoute(id: Int64) -> AnyPublisher<Bool, NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                // 暂时返回成功
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 完成路线
    func completeRoute(id: Int64) -> AnyPublisher<Bool, NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                // 暂时返回成功
                promise(.success(true))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 创建新路线
    func createRoute(_ route: CreateRouteRequest) -> AnyPublisher<Route, NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                // 创建对应的用户对象
                let creator = AuthService.shared.getUserById(route.creatorId)
                
                // 暂时返回一个简单的路线
                let newRoute = Route(
                    id: Int64(self.routes.count + 1),
                    name: route.name,
                    description: route.description,
                    creator: creator,
                    startLatitude: route.startLatitude,
                    startLongitude: route.startLongitude,
                    endLatitude: route.endLatitude,
                    endLongitude: route.endLongitude,
                    startAddress: route.startLocation,
                    endAddress: route.endLocation,
                    distance: route.distance,
                    estimatedDuration: route.estimatedDuration,
                    difficulty: route.difficulty,
                    tags: route.tags.compactMap { RouteTag(rawValue: $0) },
                    routePoints: route.waypoints,
                    coverImage: route.coverImage,
                    views: 0,
                    likes: 0,
                    collections: 0,
                    completions: 0,
                    averageRating: 0.0,
                    ratingCount: 0,
                    status: .active,
                    isPublic: route.isPublic,
                    isFeatured: false,
                    createdAt: self.getCurrentTimestamp(),
                    updatedAt: self.getCurrentTimestamp()
                )
                
                self.routes.append(newRoute)
                promise(.success(newRoute))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 获取用户创建的路线
    func fetchUserRoutes(userId: Int64) -> AnyPublisher<[Route], NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                let userRoutes = self.routes.filter { $0.creator?.id == userId }
                promise(.success(userRoutes))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // 获取用户完成的路线
    func fetchCompletedRoutes(userId: Int64) -> AnyPublisher<[Route], NetworkError> {
        return Future { promise in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                promise(.success([]))
            }
        }
        .eraseToAnyPublisher()
    }
    
    // MARK: - 辅助方法
    private func getCurrentTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        return formatter.string(from: Date())
    }
}

// MARK: - 数据结构

struct RouteFilters {
    let difficulty: Difficulty?
    let minDistance: Double?
    let maxDistance: Double?
    let minDuration: Int?
    let maxDuration: Int?
    let tags: [String]?
    let minRating: Double?
}

struct CreateRouteRequest: Codable {
    let name: String
    let description: String
    let difficulty: Difficulty
    let distance: Double
    let estimatedDuration: Int
    let startLatitude: Double
    let startLongitude: Double
    let endLatitude: Double
    let endLongitude: Double
    let waypoints: [RoutePoint]
    let tags: [String]
    let isPublic: Bool
    let coverImage: String?
    let creatorId: Int64
    let creatorName: String
    let startLocation: String
    let endLocation: String
} 

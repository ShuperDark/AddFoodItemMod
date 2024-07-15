#include "substrate.h"
#include <string>
#include <cstdio>
#include <chrono>
#include <memory>
#include <vector>
#include <mach-o/dyld.h>
#include <stdint.h>
#include <cstdlib>
#include <sys/mman.h>
#include <sys/stat.h>
#include <random>
#include <cstdint>
#include <unordered_map>
#include <map>
#include <functional>
#include <cmath>
#include <chrono>
#include <libkern/OSCacheControl.h>
#include <cstddef>
#include <tuple>
#include <mach/mach.h>
#include <mach-o/getsect.h>
#include <mach-o/loader.h>
#include <mach-o/nlist.h>
#include <mach-o/reloc.h>

#include <dlfcn.h>

#import <Foundation/Foundation.h>
#import "UIKit/UIKit.h"

struct TextureUVCoordinateSet;
struct CompoundTag;
struct Material;
struct BlockSource;
struct PlayerInventoryProxy;
struct Item;

enum class UseAnimation : unsigned char {
	NONE,
	EAT,
	DRINK,
	BLOCK,
	BOW,
	CAMERA
};

enum class MaterialType : int {
	DEFAULT = 0,
	DIRT,
	WOOD,
	STONE,
	METAL,
	WATER,
	LAVA,
	PLANT,
	DECORATION,
	WOOL = 11,
	BED,
	FIRE,
	SAND,
	DEVICE,
	GLASS,
	EXPLOSIVE,
	ICE,
	PACKED_ICE,
	SNOW,
	CACTUS = 22,
	CLAY,
	PORTAL = 25,
	CAKE,
	WEB,
	CIRCUIT,
	LAMP = 30,
	SLIME
};

enum class BlockSoundType : int {
	NORMAL, GRAVEL, WOOD, GRASS, METAL, STONE, CLOTH, GLASS, SAND, SNOW, LADDER, ANVIL, SLIME, SILENT, DEFAULT, UNDEFINED
};

enum class CreativeItemCategory : unsigned char {
	BLOCKS = 1,
	DECORATIONS,
	TOOLS,
	ITEMS
};

struct Block
{
	void** vtable;
	char filler[0x90-8];
	int category;
	char filler2[0x94+0x19+0x90-4];
};

struct FoodItemComponent {
    enum struct Effect;

    /* 0x00 */ Item *item;
    /* 0x08 */ int nutrition;
    /* 0x0c */ float saturationModifier;
    /* 0x10 */ bool isMeat;
    /* 0x18 */ std::string eatSound;
    /* 0x30 */ std::string usingConvertsTo;
    /* 0x48 */ std::vector<FoodItemComponent::Effect> effects;
};

struct Item {
    void** vtable; // 0
    uint8_t maxStackSize; // 8
    int idk; // 12
    std::string atlas; // 16
    int frameCount; // 40
    bool animated; // 44
    short itemId; // 46
    std::string name; // 48
    std::string idk3; // 72
    bool isMirrored; // 96
    short maxDamage; // 98
    bool isGlint; // 100
    bool renderAsTool; // 101
    bool stackedByData; // 102
    uint8_t properties; // 103
    int maxUseDuration; // 104
    bool explodeable; // 108
    bool shouldDespawn; // 109
    bool idk4; // 110
    uint8_t useAnimation; // 111
    int creativeCategory; // 112
    float idk5; // 116
    float idk6; // 120
    char buffer[12]; // 124
    TextureUVCoordinateSet* icon; // 136
    void* idk7; // 144
    std::unique_ptr<FoodItemComponent> foodComponent; // 152
    void* seedComponent; // 160
    void* cameraComponent; // 168

    struct Tier {
        int level;
        int uses;
        float speed;
        int damage;
        int enchantmentValue;
    };
};

struct WeaponItem : public Item {
    int damage;
    Item::Tier* tier;
};

struct DiggerItem : public Item {
    float speed; // 0xb4
    Item::Tier* tier; // 0xc0
    int attackDamage; // 0xc4
    char filler[0x1E0-0xC4];
};

struct PickaxeItem : public DiggerItem {};

struct BlockItem :public Item {
	char filler[0xB0];
};

struct ItemInstance {
	uint8_t count;
	uint16_t aux;
	CompoundTag* tag;
	Item* item;
	Block* block;
	int idk[3];
};

struct BlockGraphics {
	void** vtable;
	char filler[0x20 - 8];
	int blockShape;
	char filler2[0x3C0 - 0x20 - 4];
};

struct LevelData {
	char filler[48];
	std::string levelName;
	char filler2[44];
	int time;
	char filler3[144];
	int gameType;
	int difficulty;
};

struct Level {
	char filler[160];
	LevelData* data;
};

struct Entity {
	char filler[64];
	Level* level;
	char filler2[104];
	BlockSource* region;
};

struct Player :public Entity {
	char filler[4400];
	PlayerInventoryProxy* inventory;
};

struct Vec3 {
	float x, y, z;

	Vec3(float _x, float _y, float _z) : x(_x), y(_y), z(_z) {}

	float distanceTo(float _x, float _y, float _z) const {

		return (float) sqrt((x - _x) * (x - _x) + (y - _y) * (y - _y) + (z - _z) * (z - _z));
	}

	float distanceTo(Vec3 const& v) const {

		return distanceTo(v.x, v.y, v.z);
	}

	bool operator!=(Vec3 const& other) const {
		return x == other.x || y == other.y || z == other.z;
	}

	bool operator==(Vec3 const& other) const {
        return x == other.x && y == other.y && z == other.z;
    }

    Vec3 operator+(Vec3 const& v) const {
    	return {this->x + v.x, this->y + v.y, this->z + v.z};
    }

    Vec3 operator-(Vec3 const& v) const {
    	return {this->x - v.x, this->y - v.y, this->z - v.z};
    }

    Vec3 operator-() const {
    	return {-x, -y, -z};
    }

    Vec3 operator*(float times) const {
    	return {x * times, y * times, z * times};
    };

    Vec3 operator/(float value) const {
    	return {x / value, y / value, z / value};
    };

    Vec3 operator*(Vec3 const& v) const {
    	return {x * v.x, y * v.y, z * v.z};
    }
};

struct BlockPos {
	int x, y, z;

	BlockPos() : BlockPos(0, 0, 0) {}

    BlockPos(int x, int y, int z) : x(x), y(y), z(z) {}

    BlockPos(Vec3 const &v) : x((int) floorf(v.x)), y((int) floorf(v.y)), z((int) floorf(v.z)) {}

    BlockPos(BlockPos const &blockPos) : BlockPos(blockPos.x, blockPos.y, blockPos.z) {}

    bool operator==(BlockPos const &pos) const {
        return x == pos.x && y == pos.y && z == pos.z;
    }
    bool operator!=(BlockPos const &pos) const {
        return x != pos.x || y != pos.y || z != pos.z;
    }
    bool operator<(BlockPos const& pos) const {
        return std::make_tuple(x, y, z) < std::make_tuple(pos.x, pos.y, pos.z);
    }

	BlockPos getSide(unsigned char side) const {
        switch (side) {
            case 0:
                return {x, y - 1, z};
            case 1:
                return {x, y + 1, z};
            case 2:
                return {x, y, z - 1};
            case 3:
                return {x, y, z + 1};
            case 4:
                return {x - 1, y, z};
            case 5:
                return {x + 1, y, z};
            default:
                return {x, y, z};
        }
	}
};

namespace Json { class Value; }

static Item*** Item$mItems;

static Item*(*Item$Item)(Item*, std::string const&, short);
static Item*(*Item$setIcon)(Item*, std::string const&, int);
static Item*(*Item$setMaxStackSize)(Item*, unsigned char);
static Item*(*Item$setUseAnimation)(Item*, UseAnimation);
static Item*(*Item$setMaxUseDuration)(Item*, int);
static void(*Item$addCreativeItem)(ItemInstance const&);

static ItemInstance*(*ItemInstance$ItemInstance)(ItemInstance*, int, int, int);

static FoodItemComponent*(*FoodItemComponent$FoodItemComponent)(FoodItemComponent*, Item&);

int tamagokake = 1002;
int katsudon = 1003;
int ramen = 1004;

Item* tamagokakePtr;
Item* katsudonPtr;
Item* ramenPtr;

static uintptr_t** VTAppPlatformiOS;

static bool (*_File$exists)(std::string const&);
static bool File$exists(std::string const& path) {
	if(path.find("minecraftpe.app/data/resourcepacks/vanilla/client/textures/items/tamagokake.png") != std::string::npos || path.find("minecraftpe.app/data/resourcepacks/vanilla/client/textures/items/katsudon.png") != std::string::npos || path.find("minecraftpe.app/data/resourcepacks/vanilla/client/textures/items/ramen.png") != std::string::npos)
		return true;

	return _File$exists(path);
}

static std::string (*_AppPlatformiOS$readAssetFile)(uintptr_t*, std::string const&);
static std::string AppPlatformiOS$readAssetFile(uintptr_t* self, std::string const& str) {

    if (strstr(str.c_str(), "minecraftpe.app/data/resourcepacks/vanilla/client/textures/items/tamagokake.png"))
        return _AppPlatformiOS$readAssetFile(self, "/Library/Application Support/addfooditemmod/tamagokake.png");
    if (strstr(str.c_str(), "minecraftpe.app/data/resourcepacks/vanilla/client/textures/items/katsudon.png"))
        return _AppPlatformiOS$readAssetFile(self, "/Library/Application Support/addfooditemmod/katsudon.png");
    if (strstr(str.c_str(), "minecraftpe.app/data/resourcepacks/vanilla/client/textures/items/ramen.png"))
        return _AppPlatformiOS$readAssetFile(self, "/Library/Application Support/addfooditemmod/ramen.png");

    std::string content = _AppPlatformiOS$readAssetFile(self, str);
    if (strstr(str.c_str(), "minecraftpe.app/data/resourcepacks/vanilla/client/textures/item_texture.json")) {
        NSString *jsonString = [NSString stringWithUTF8String:content.c_str()];
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
        NSError *jsonError;
        NSMutableDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&jsonError];

        NSMutableDictionary *jsonTextureData = [jsonDict objectForKey:@"texture_data"];
        [jsonTextureData setObject:@{
            @"textures": @[@"textures/items/tamagokake"]
        } forKey:@"tamagokake"];
        [jsonTextureData setObject:@{
            @"textures": @[@"textures/items/katsudon"]
        } forKey:@"katsudon"];
        [jsonTextureData setObject:@{
            @"textures": @[@"textures/items/ramen"]
        } forKey:@"ramen"];
       
        jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:&jsonError];
        jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        content = std::string([jsonString UTF8String]);
    }
    return content;
}

static void (*_Item$initCreativeItems)();
static void Item$initCreativeItems() {
	_Item$initCreativeItems();

	ItemInstance tamagokake_inst;
	ItemInstance$ItemInstance(&tamagokake_inst, tamagokake, 1, 0);
	Item$addCreativeItem(tamagokake_inst);

	ItemInstance katsudon_inst;
	ItemInstance$ItemInstance(&katsudon_inst, katsudon, 1, 0);
	Item$addCreativeItem(katsudon_inst);

	ItemInstance ramen_inst;
	ItemInstance$ItemInstance(&ramen_inst, ramen, 1, 0);
	Item$addCreativeItem(ramen_inst);
}

static void (*_Item$registerItems)();
static void Item$registerItems() {
	_Item$registerItems();

	tamagokakePtr = new Item();
	Item$Item(tamagokakePtr, "tamagokake", tamagokake - 0x100);
	Item$mItems[1][tamagokake] = tamagokakePtr;
	tamagokakePtr->creativeCategory = 4;
	Item$setMaxStackSize(tamagokakePtr, 64);
	Item$setUseAnimation(tamagokakePtr, UseAnimation::EAT);
	Item$setMaxUseDuration(tamagokakePtr, 32);
	tamagokakePtr->foodComponent = std::make_unique<FoodItemComponent>();
	FoodItemComponent$FoodItemComponent(tamagokakePtr->foodComponent.get(), *tamagokakePtr);
	tamagokakePtr->foodComponent->nutrition = 10;
	tamagokakePtr->foodComponent->saturationModifier = 4.f;
	tamagokakePtr->foodComponent->isMeat = false;

	katsudonPtr = new Item();
	Item$Item(katsudonPtr, "katsudon", katsudon - 0x100);
	Item$mItems[1][katsudon] = katsudonPtr;
	katsudonPtr->creativeCategory = 4;
	Item$setMaxStackSize(katsudonPtr, 64);
	Item$setUseAnimation(katsudonPtr, UseAnimation::EAT);
	Item$setMaxUseDuration(katsudonPtr, 32);
	katsudonPtr->foodComponent = std::make_unique<FoodItemComponent>();
	FoodItemComponent$FoodItemComponent(katsudonPtr->foodComponent.get(), *katsudonPtr);
	katsudonPtr->foodComponent->nutrition = 10;
	katsudonPtr->foodComponent->saturationModifier = 4.f;
	katsudonPtr->foodComponent->isMeat = false;

	ramenPtr = new Item();
	Item$Item(ramenPtr, "ramen", ramen - 0x100);
	Item$mItems[1][ramen] = ramenPtr;
	ramenPtr->creativeCategory = 4;
	Item$setMaxStackSize(ramenPtr, 64);
	Item$setUseAnimation(ramenPtr, UseAnimation::EAT);
	Item$setMaxUseDuration(ramenPtr, 32);
	ramenPtr->foodComponent = std::make_unique<FoodItemComponent>();
	FoodItemComponent$FoodItemComponent(ramenPtr->foodComponent.get(), *ramenPtr);
	ramenPtr->foodComponent->nutrition = 10;
	ramenPtr->foodComponent->saturationModifier = 4.f;
	ramenPtr->foodComponent->isMeat = false;
}

static void (*_Item$initClientData)();
static void Item$initClientData() {
	_Item$initClientData();

	Item$setIcon(tamagokakePtr, "tamagokake", 0);

	Item$setIcon(katsudonPtr, "katsudon", 0);

	Item$setIcon(ramenPtr, "ramen", 0);
}

%ctor {
	VTAppPlatformiOS = (uintptr_t**)(0x1011695f0 + _dyld_get_image_vmaddr_slide(0));
	_AppPlatformiOS$readAssetFile = (std::string(*)(uintptr_t*, std::string const&)) VTAppPlatformiOS[58];
	VTAppPlatformiOS[58] = (uintptr_t*)&AppPlatformiOS$readAssetFile;

	Item$mItems = (Item***)(0x1012ae238 + _dyld_get_image_vmaddr_slide(0));

	Item$Item = (Item*(*)(Item*, std::string const&, short))(0x10074689c + _dyld_get_image_vmaddr_slide(0));
	Item$setIcon = (Item*(*)(Item*, std::string const&, int))(0x100746b0c + _dyld_get_image_vmaddr_slide(0));
	Item$setMaxStackSize = (Item*(*)(Item*, unsigned char))(0x100746a88 + _dyld_get_image_vmaddr_slide(0));
	Item$setUseAnimation = (Item*(*)(Item*, UseAnimation))(0x100726a2c + _dyld_get_image_vmaddr_slide(0));
	Item$setMaxUseDuration = (Item*(*)(Item*, int))(0x100726a34 + _dyld_get_image_vmaddr_slide(0));
	Item$addCreativeItem = (void(*)(ItemInstance const&))(0x100745f10 + _dyld_get_image_vmaddr_slide(0));

	ItemInstance$ItemInstance = (ItemInstance*(*)(ItemInstance*, int, int, int))(0x100756c70 + _dyld_get_image_vmaddr_slide(0));

	FoodItemComponent$FoodItemComponent = (FoodItemComponent*(*)(FoodItemComponent*, Item&))(0x100730134 + _dyld_get_image_vmaddr_slide(0));

	MSHookFunction((void*)(0x1005316ec + _dyld_get_image_vmaddr_slide(0)), (void*)&File$exists, (void**)&_File$exists);

	MSHookFunction((void*)(0x100734d00 + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$initCreativeItems, (void**)&_Item$initCreativeItems);
	MSHookFunction((void*)(0x100733348 + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$registerItems, (void**)&_Item$registerItems);
	MSHookFunction((void*)(0x10074242c + _dyld_get_image_vmaddr_slide(0)), (void*)&Item$initClientData, (void**)&_Item$initClientData);
}
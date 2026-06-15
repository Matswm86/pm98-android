// FUN_005d4410  entry=005d4410  size=406 bytes

undefined4 __thiscall
FUN_005d4410(int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5
            ,undefined4 param_6,undefined4 param_7,undefined4 param_8)

{
  undefined4 uVar1;
  undefined4 *puVar2;
  undefined4 uVar3;
  undefined1 local_20 [16];
  undefined1 local_10 [16];
  
  uVar1 = param_8;
  uVar3 = param_8;
  FUN_004ac740(&param_7);
  uVar1 = FUN_005bc780(param_2,param_3,param_4,param_5,param_6,uVar1,uVar3);
  *(undefined4 *)(param_1 + 0x3f8) = 0;
  *(undefined4 *)(param_1 + 0x3f4) = 0;
  *(undefined4 *)(param_1 + 0x400) = 0;
  param_8 = 0;
  puVar2 = (undefined4 *)FUN_005d4300(&param_6,&param_8,0x98);
  *(undefined4 *)(param_1 + 0x404) = *puVar2;
  param_8 = 0xffffff;
  puVar2 = (undefined4 *)FUN_005d4300(&param_6,&param_8,0x82);
  *(undefined4 *)(param_1 + 0x408) = *puVar2;
  param_8 = 0xffffff;
  puVar2 = (undefined4 *)FUN_005d4300(&param_6,&param_8,0x3e);
  *(undefined4 *)(param_1 + 0x40c) = *puVar2;
  param_8 = 0xffffff;
  puVar2 = (undefined4 *)FUN_005d4300(&param_6,&param_8,0xae);
  *(undefined4 *)(param_1 + 0x410) = *puVar2;
  param_8 = 0xffffff;
  puVar2 = (undefined4 *)FUN_005d4300(&param_6,&param_8,0x3e);
  *(undefined4 *)(param_1 + 0x414) = *puVar2;
  *(undefined4 *)(param_1 + 0x3fc) = 6;
  if ((*(uint *)(param_1 + 0xac) & 0x400000) != 0) {
    FUN_00437be0(local_20,param_1 + 0x78);
    puVar2 = (undefined4 *)FUN_004aa3e0(local_10,local_20);
    *(undefined4 *)(param_1 + 0x88) = *puVar2;
    *(undefined4 *)(param_1 + 0x8c) = puVar2[1];
    *(undefined4 *)(param_1 + 0x90) = puVar2[2];
    *(undefined4 *)(param_1 + 0x94) = puVar2[3];
  }
  return uVar1;
}



// FUN_005261f0  entry=005261f0  size=199 bytes

int __thiscall FUN_005261f0(int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4)

{
  bool bVar1;
  int iVar2;
  undefined4 uVar3;
  
  uVar3 = 0xffffff;
  iVar2 = param_1;
  FUN_00437020(0x18,0x34,99);
  iVar2 = FUN_005bc780(param_2,param_3,&DAT_00666f70,0,0,iVar2,uVar3);
  if (iVar2 != 0) {
    if ((*(int *)(param_1 + 0x3f8) == 0) && (*(int *)(param_1 + 0x3f4) == 0)) {
      bVar1 = false;
    }
    else {
      bVar1 = true;
    }
    if (!bVar1) {
      FUN_005c9f60(s_RECURSOS_iconos_starparon_bmp_006591c8,0,0xffffffff);
      FUN_005c9f60(s_RECURSOS_iconos_starparon_off_bm_006591a4,0,0xffffffff);
      FUN_005d66f0((int *)(param_1 + 0x3f4),0x100);
      FUN_005d66f0(param_1 + 0x440,0x100);
    }
    FUN_005beae0(s_ProMan10_006551e0);
    *(undefined4 *)(param_1 + 0x54) = param_4;
  }
  return iVar2;
}



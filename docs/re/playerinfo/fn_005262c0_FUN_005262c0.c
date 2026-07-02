// FUN_005262c0  entry=005262c0  size=205 bytes

int __thiscall FUN_005262c0(int param_1,undefined4 param_2,undefined4 param_3,int param_4)

{
  bool bVar1;
  int iVar2;
  undefined4 uVar3;
  char local_100 [256];
  
  uVar3 = 0xffffffff;
  iVar2 = param_1;
  FUN_00436270(0);
  iVar2 = FUN_005bc780(param_2,param_3,&DAT_00666f70,0x800,0,iVar2,uVar3);
  if (iVar2 != 0) {
    if ((*(int *)(param_1 + 0x3f8) == 0) && (*(int *)(param_1 + 0x3f4) == 0)) {
      bVar1 = false;
    }
    else {
      bVar1 = true;
    }
    if (!bVar1) {
      sprintf(local_100,s_RECURSOS_iconos_camrol_02u_bmp_0065bbe4,*(byte *)(param_4 + 0x18) + 1);
      FUN_005c9f60(local_100,0,0xffffffff);
      FUN_005c9f60(s_recursos_iconos_seguros_minisegu_0065bbbc,0,0xffffffff);
    }
    FUN_005beae0(s_ProMan10_006551e0);
    *(int *)(param_1 + 0x54) = param_4;
  }
  return iVar2;
}



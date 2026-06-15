// FUN_0050b580  entry=0050b580  size=107 bytes

int __thiscall
FUN_0050b580(int param_1,undefined4 param_2,undefined4 param_3,undefined4 param_4,undefined4 param_5
            )

{
  int iVar1;
  undefined4 uVar2;
  
  uVar2 = 0xffffff;
  iVar1 = param_1;
  FUN_00436270(0xffffff);
  iVar1 = FUN_005c55b0(param_2,param_3,param_4,8,0,iVar1,uVar2);
  if (iVar1 != 0) {
    *(undefined4 *)(param_1 + 0x430) = param_5;
    FUN_005beae0(s_ProMan10_006551e0);
    FUN_005c9f60(s_recursos_iconos_directiva_pico_b_0065a354,0,0xffffffff);
  }
  return iVar1;
}



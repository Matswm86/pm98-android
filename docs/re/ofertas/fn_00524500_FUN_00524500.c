// FUN_00524500  entry=00524500  size=285 bytes

int __thiscall
FUN_00524500(int param_1,undefined4 param_2,undefined4 param_3,int param_4,int param_5)

{
  undefined4 uVar1;
  int iVar2;
  undefined1 *puVar3;
  undefined4 uVar4;
  undefined4 uVar5;
  undefined4 uVar6;
  char local_100 [256];
  
  uVar6 = 0xffffff;
  iVar2 = param_1;
  FUN_00436270(0);
  uVar5 = 0;
  uVar4 = 0;
  puVar3 = &DAT_00666f70;
  uVar1 = FUN_00436fb0(0x234,0x30);
  uVar1 = FUN_00436fd0(param_3,uVar1);
  iVar2 = FUN_005d4410(param_2,uVar1,puVar3,uVar4,uVar5,iVar2,uVar6);
  if (iVar2 != 0) {
    *(int *)(param_1 + 0x418) = param_4;
    *(int *)(param_1 + 0x41c) = param_5;
    if (param_4 != 0) {
      sprintf(local_100,s_recursos_iconos_camrol_02u_bmp_00658a10,*(byte *)(param_4 + 0x18) + 1);
      FUN_005c9f60(local_100,0,0xffffffff);
    }
    if (param_5 != 0) {
      FUN_005c9f60(s_recursos_iconos_descenso_bmp_0065b798,0,0xffffffff);
      FUN_005c9f60(s_recursos_iconos_partidos_bmp_0065b778,0,0xffffffff);
      FUN_005c9f60(s_recursos_iconos_primasgol_bmp_0065b758,0,0xffffffff);
      FUN_005c9f60(s_recursos_iconos_casacoche_bmp_0065b738,0,0xffffffff);
    }
    FUN_005beae0(s_ProMan8_00658928);
  }
  return iVar2;
}



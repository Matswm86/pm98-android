// FUN_004f50c0  entry=004f50c0  size=288 bytes

int __thiscall FUN_004f50c0(int param_1,undefined4 param_2,undefined4 param_3)

{
  int iVar1;
  uint uVar2;
  undefined4 uVar3;
  char local_100 [256];
  
  uVar3 = 0xffffffff;
  iVar1 = param_1;
  FUN_00436270(0xffffffff);
  iVar1 = FUN_005bc780(param_2,param_3,&DAT_00666f70,0,0,iVar1,uVar3);
  *(undefined4 *)(param_1 + 0x3f4) = 0;
  if (iVar1 != 0) {
    uVar2 = 0;
    do {
      uVar2 = uVar2 + 1;
      sprintf(local_100,s_recursos_iconos_camrol_02u_bmp_00658a10,uVar2);
      FUN_005c9f60(local_100,0,0xffffffff);
    } while (uVar2 < 0x12);
    uVar2 = 0;
    do {
      sprintf(local_100,s_recursos_iconos_incidencia_u_bmp_006589ec,uVar2);
      FUN_005c9f60(local_100,0,0xffffffff);
      uVar2 = uVar2 + 1;
    } while (uVar2 < 10);
    FUN_005c9f60(s_recursos_iconos_starjugon_bmp_006589cc,0,0xffffffff);
    FUN_005c9f60(s_recursos_iconos_starjugon_off_bm_006589a8,0,0xffffffff);
    FUN_005d66f0(param_1 + 0x950,0x100);
    FUN_005d66f0(param_1 + 0x99c,0x100);
  }
  return iVar1;
}



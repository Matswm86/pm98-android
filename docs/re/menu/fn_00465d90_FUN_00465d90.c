// FUN_00465d90  entry=00465d90  size=526 bytes

undefined4 __thiscall FUN_00465d90(int param_1,undefined4 param_2,short param_3)

{
  short sVar1;
  LPCSTR pCVar2;
  int iVar3;
  int iVar4;
  uint uVar5;
  uint uVar6;
  uint uVar7;
  uint uVar8;
  char *pcVar9;
  undefined1 *puVar10;
  undefined4 uVar11;
  uint uVar12;
  undefined4 local_d8;
  undefined4 local_d4;
  undefined4 local_d0;
  undefined4 local_cc;
  undefined1 local_c8 [200];
  
  local_d8 = 0x217;
  local_d4 = 8;
  local_d0 = 0x285;
  local_cc = 0x35;
  uVar11 = 0xffffffff;
  iVar3 = param_1;
  FUN_00436270(0xffffffff);
  FUN_005bc780(param_2,&local_d8,&DAT_00666f70,0x800,0,iVar3,uVar11);
  FUN_005beae0(s_Calend12_00653ce0);
  FUN_00468c70(0);
  switch(DAT_0066b1dc) {
  case 0:
  case 1:
  case 2:
  case 3:
    pcVar9 = s_img_premier_copas_league_bmp_00653be8;
    break;
  case 4:
    pcVar9 = s_img_premier_copas_facup_bmp_00653c28;
    break;
  case 5:
    pcVar9 = s_img_premier_copas_cocacola_bmp_00653bc8;
    break;
  case 6:
    pcVar9 = s_img_premier_copas_charity_bmp_00653c08;
    break;
  case 7:
    pcVar9 = s_img_copas_uefa_bmp_00653cac;
    break;
  case 8:
    pcVar9 = s_img_copas_recopa_bmp_00653c94;
    break;
  case 9:
    pcVar9 = s_img_copas_ligacampeones_bmp_00653c78;
    break;
  case 10:
    pcVar9 = s_img_copas_supercopa_europa_bmp_00653cc0;
    break;
  case 0xb:
    pcVar9 = s_img_copas_intercontinental_bmp_00653c58;
    break;
  default:
    goto switchD_00465e15_caseD_c;
  case 0xd:
    pcVar9 = s_img_copas_balon_bmp_00653c44;
  }
  FUN_005c9f60(pcVar9,0,0xffffffff);
switchD_00465e15_caseD_c:
  puVar10 = local_c8;
  *(short *)(param_1 + 0x4c0) = param_3;
  uVar12 = 100;
  pCVar2 = (LPCSTR)(**(code **)(*DAT_0066b1e0 + 0x10))(puVar10,100);
  if (pCVar2 == (LPCSTR)0x0) {
    return 0;
  }
  lstrcpyA((LPSTR)(param_1 + 0x3f4),pCVar2);
  iVar3 = (**(code **)(*DAT_0066b1e0 + 0x4c))();
  uVar7 = 0;
  iVar4 = (**(code **)(*DAT_0066b1e0 + 0x4c))();
  if (iVar4 != 0) {
    do {
      uVar8 = 0;
      uVar6 = uVar7;
      iVar4 = (**(code **)(*DAT_0066b1e0 + 0x50))(uVar7);
      if (iVar4 != 0) {
        do {
          sVar1 = (**(code **)(*DAT_0066b1e0 + 0x54))(uVar7,uVar8);
          if (sVar1 == param_3) {
            uVar12 = uVar7;
          }
          uVar8 = uVar8 + 1;
          uVar5 = (**(code **)(*DAT_0066b1e0 + 0x50))(uVar7);
        } while (uVar8 < uVar5);
      }
      uVar7 = uVar7 + 1;
      uVar6 = (**(code **)(*DAT_0066b1e0 + 0x4c))(uVar6,puVar10,uVar12);
    } while (uVar7 < uVar6);
  }
  iVar4 = (**(code **)(*DAT_0066b1e0 + 0x4c))();
  if (iVar3 == iVar4) {
    iVar3 = 0;
  }
  pCVar2 = (LPCSTR)(**(code **)(*DAT_0066b1e0 + 0x1c))(iVar3,&DAT_0066b18c,&local_d0,100);
  if (pCVar2 == (LPCSTR)0x0) {
    return 0;
  }
  lstrcpyA((LPSTR)(param_1 + 0x434),pCVar2);
  return 1;
}



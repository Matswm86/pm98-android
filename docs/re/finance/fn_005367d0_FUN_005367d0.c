// FUN_005367d0  entry=005367d0  size=857 bytes

/* WARNING: Globals starting with '_' overlap smaller symbols at the same address */

void __thiscall FUN_005367d0(int param_1,char *param_2)

{
  char cVar1;
  int iVar2;
  int iVar3;
  undefined4 uVar4;
  uint uVar5;
  uint uVar6;
  int unaff_EBX;
  char *pcVar7;
  char *pcVar8;
  char *pcVar9;
  float10 fVar10;
  undefined4 local_204 [64];
  undefined1 auStack_104 [260];
  
  iVar3 = *(int *)(param_1 + 0x2920);
  iVar2 = *(int *)(iVar3 + 0x50);
  local_204[0] = *(undefined4 *)(iVar3 + 0x58);
  FUN_0057cc60(*(undefined4 *)(iVar3 + 0x10),0,1,*(undefined4 *)(iVar3 + 4));
  sprintf(param_2,s_As_manager__s_s__you_have_0065c63c);
  iVar3 = FUN_0057a520();
  if (iVar3 == 0) {
    uVar5 = 0xffffffff;
    pcVar8 = &DAT_0065c634;
    do {
      pcVar7 = pcVar8;
      if (uVar5 == 0) break;
      uVar5 = uVar5 - 1;
      pcVar7 = pcVar8 + 1;
      cVar1 = *pcVar8;
      pcVar8 = pcVar7;
    } while (cVar1 != '\0');
    uVar5 = ~uVar5;
    iVar3 = -1;
    pcVar8 = param_2;
    do {
      pcVar9 = pcVar8;
      if (iVar3 == 0) break;
      iVar3 = iVar3 + -1;
      pcVar9 = pcVar8 + 1;
      cVar1 = *pcVar8;
      pcVar8 = pcVar9;
    } while (cVar1 != '\0');
    pcVar8 = pcVar7 + -uVar5;
    pcVar7 = pcVar9 + -1;
    for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
      *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
      pcVar8 = pcVar8 + 4;
      pcVar7 = pcVar7 + 4;
    }
    for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
      *pcVar7 = *pcVar8;
      pcVar8 = pcVar8 + 1;
      pcVar7 = pcVar7 + 1;
    }
  }
  uVar5 = 0xffffffff;
  pcVar8 = s_achieved_the_objective_you_have_b_0065c604;
  do {
    pcVar7 = pcVar8;
    if (uVar5 == 0) break;
    uVar5 = uVar5 - 1;
    pcVar7 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar7;
  } while (cVar1 != '\0');
  uVar5 = ~uVar5;
  iVar3 = -1;
  pcVar8 = param_2;
  do {
    pcVar9 = pcVar8;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar9 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar9;
  } while (cVar1 != '\0');
  pcVar8 = pcVar7 + -uVar5;
  pcVar7 = pcVar9 + -1;
  for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
    *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
    pcVar8 = pcVar8 + 4;
    pcVar7 = pcVar7 + 4;
  }
  for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
    *pcVar7 = *pcVar8;
    pcVar8 = pcVar8 + 1;
    pcVar7 = pcVar7 + 1;
  }
  (**(code **)(*(int *)(&DAT_0066b190)[iVar2] + 0x7c))(local_204[0]);
  sprintf((char *)local_204,s___s___0065c5fc);
  uVar5 = 0xffffffff;
  pcVar8 = (char *)local_204;
  do {
    pcVar7 = pcVar8;
    if (uVar5 == 0) break;
    uVar5 = uVar5 - 1;
    pcVar7 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar7;
  } while (cVar1 != '\0');
  uVar5 = ~uVar5;
  iVar3 = -1;
  pcVar8 = param_2;
  do {
    pcVar9 = pcVar8;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar9 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar9;
  } while (cVar1 != '\0');
  pcVar8 = pcVar7 + -uVar5;
  pcVar7 = pcVar9 + -1;
  for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
    *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
    pcVar8 = pcVar8 + 4;
    pcVar7 = pcVar7 + 4;
  }
  for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
    *pcVar7 = *pcVar8;
    pcVar8 = pcVar8 + 1;
    pcVar7 = pcVar7 + 1;
  }
  iVar3 = *(int *)(*(int *)(param_1 + 0x2920) + 0x4c);
  if (iVar3 == 0) {
    (**(code **)(*(int *)(&DAT_0066b190)[unaff_EBX] + 0xc))();
    pcVar8 = s_You_began_the_season_as_Champion_0065c570;
LAB_00536948:
    sprintf((char *)local_204,pcVar8);
  }
  else {
    if (iVar3 == 1) {
      (**(code **)(*(int *)(&DAT_0066b190)[unaff_EBX] + 0xc))();
      pcVar8 = s_You_began_the_season_as__s_runne_0065c59c;
      goto LAB_00536948;
    }
    uVar4 = FUN_0058de90(auStack_104);
    (**(code **)(*(int *)(&DAT_0066b190)[unaff_EBX] + 0xc))();
    sprintf((char *)local_204,s_You_began_the_season_in_the__s_p_0065c5c8,uVar4);
  }
  uVar5 = 0xffffffff;
  pcVar8 = (char *)local_204;
  do {
    pcVar7 = pcVar8;
    if (uVar5 == 0) break;
    uVar5 = uVar5 - 1;
    pcVar7 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar7;
  } while (cVar1 != '\0');
  uVar5 = ~uVar5;
  iVar3 = -1;
  pcVar8 = param_2;
  do {
    pcVar9 = pcVar8;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar9 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar9;
  } while (cVar1 != '\0');
  pcVar8 = pcVar7 + -uVar5;
  pcVar7 = pcVar9 + -1;
  for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
    *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
    pcVar8 = pcVar8 + 4;
    pcVar7 = pcVar7 + 4;
  }
  for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
    *pcVar7 = *pcVar8;
    pcVar8 = pcVar8 + 1;
    pcVar7 = pcVar7 + 1;
  }
  iVar3 = FUN_0057d1c0();
  if (iVar3 == 0) {
    pcVar8 = s_have_finished_as_the_Champion__0065c508;
  }
  else {
    if (iVar3 != 1) {
      FUN_0058de90(auStack_104);
      sprintf((char *)local_204,s_have_finished_in_the__s_position_0065c54c);
      goto LAB_005369eb;
    }
    pcVar8 = s_have_finished_as_runner_up__0065c52c;
  }
  uVar5 = 0xffffffff;
  do {
    pcVar7 = pcVar8;
    if (uVar5 == 0) break;
    uVar5 = uVar5 - 1;
    pcVar7 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar7;
  } while (cVar1 != '\0');
  uVar5 = ~uVar5;
  pcVar8 = pcVar7 + -uVar5;
  pcVar7 = (char *)local_204;
  for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
    *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
    pcVar8 = pcVar8 + 4;
    pcVar7 = pcVar7 + 4;
  }
  for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
    *pcVar7 = *pcVar8;
    pcVar8 = pcVar8 + 1;
    pcVar7 = pcVar7 + 1;
  }
LAB_005369eb:
  uVar5 = 0xffffffff;
  pcVar8 = (char *)local_204;
  do {
    pcVar7 = pcVar8;
    if (uVar5 == 0) break;
    uVar5 = uVar5 - 1;
    pcVar7 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar7;
  } while (cVar1 != '\0');
  uVar5 = ~uVar5;
  iVar3 = -1;
  pcVar8 = param_2;
  do {
    pcVar9 = pcVar8;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar9 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar9;
  } while (cVar1 != '\0');
  pcVar8 = pcVar7 + -uVar5;
  pcVar7 = pcVar9 + -1;
  for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
    *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
    pcVar8 = pcVar8 + 4;
    pcVar7 = pcVar7 + 4;
  }
  for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
    *pcVar7 = *pcVar8;
    pcVar8 = pcVar8 + 1;
    pcVar7 = pcVar7 + 1;
  }
  uVar5 = 0xffffffff;
  pcVar8 = s_The_directors_are_0065c4f4;
  do {
    pcVar7 = pcVar8;
    if (uVar5 == 0) break;
    uVar5 = uVar5 - 1;
    pcVar7 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar7;
  } while (cVar1 != '\0');
  uVar5 = ~uVar5;
  iVar3 = -1;
  pcVar8 = param_2;
  do {
    pcVar9 = pcVar8;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar9 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar9;
  } while (cVar1 != '\0');
  pcVar8 = pcVar7 + -uVar5;
  pcVar7 = pcVar9 + -1;
  for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
    *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
    pcVar8 = pcVar8 + 4;
    pcVar7 = pcVar7 + 4;
  }
  for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
    *pcVar7 = *pcVar8;
    pcVar8 = pcVar8 + 1;
    pcVar7 = pcVar7 + 1;
  }
  iVar3 = FUN_0057a570();
  pcVar8 = s_disappointed_0065c4e4;
  if (iVar3 != 0) {
    pcVar8 = s_pleased_0065c4dc;
  }
  uVar5 = 0xffffffff;
  do {
    pcVar7 = pcVar8;
    if (uVar5 == 0) break;
    uVar5 = uVar5 - 1;
    pcVar7 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar7;
  } while (cVar1 != '\0');
  uVar5 = ~uVar5;
  iVar3 = -1;
  pcVar8 = param_2;
  do {
    pcVar9 = pcVar8;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar9 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar9;
  } while (cVar1 != '\0');
  pcVar8 = pcVar7 + -uVar5;
  pcVar7 = pcVar9 + -1;
  for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
    *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
    pcVar8 = pcVar8 + 4;
    pcVar7 = pcVar7 + 4;
  }
  for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
    *pcVar7 = *pcVar8;
    pcVar8 = pcVar8 + 1;
    pcVar7 = pcVar7 + 1;
  }
  uVar5 = 0xffffffff;
  pcVar8 = s_with_the_results__0065c4c8;
  do {
    pcVar7 = pcVar8;
    if (uVar5 == 0) break;
    uVar5 = uVar5 - 1;
    pcVar7 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar7;
  } while (cVar1 != '\0');
  uVar5 = ~uVar5;
  iVar3 = -1;
  pcVar8 = param_2;
  do {
    pcVar9 = pcVar8;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar9 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar9;
  } while (cVar1 != '\0');
  pcVar8 = pcVar7 + -uVar5;
  pcVar7 = pcVar9 + -1;
  for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
    *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
    pcVar8 = pcVar8 + 4;
    pcVar7 = pcVar7 + 4;
  }
  for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
    *pcVar7 = *pcVar8;
    pcVar8 = pcVar8 + 1;
    pcVar7 = pcVar7 + 1;
  }
  fVar10 = (float10)FUN_0057f790();
  if (fVar10 <= (float10)_DAT_00632248) {
    return;
  }
  FUN_0058dbb0(auStack_104,(double)fVar10);
  sprintf((char *)local_204,s_You_receive_a_bonus_of__s_for_la_0065c49c);
  uVar5 = 0xffffffff;
  pcVar8 = (char *)local_204;
  do {
    pcVar7 = pcVar8;
    if (uVar5 == 0) break;
    uVar5 = uVar5 - 1;
    pcVar7 = pcVar8 + 1;
    cVar1 = *pcVar8;
    pcVar8 = pcVar7;
  } while (cVar1 != '\0');
  uVar5 = ~uVar5;
  iVar3 = -1;
  do {
    pcVar8 = param_2;
    if (iVar3 == 0) break;
    iVar3 = iVar3 + -1;
    pcVar8 = param_2 + 1;
    cVar1 = *param_2;
    param_2 = pcVar8;
  } while (cVar1 != '\0');
  pcVar7 = pcVar7 + -uVar5;
  pcVar8 = pcVar8 + -1;
  for (uVar6 = uVar5 >> 2; uVar6 != 0; uVar6 = uVar6 - 1) {
    *(undefined4 *)pcVar8 = *(undefined4 *)pcVar7;
    pcVar7 = pcVar7 + 4;
    pcVar8 = pcVar8 + 4;
  }
  for (uVar5 = uVar5 & 3; uVar5 != 0; uVar5 = uVar5 - 1) {
    *pcVar8 = *pcVar7;
    pcVar7 = pcVar7 + 1;
    pcVar8 = pcVar8 + 1;
  }
  return;
}



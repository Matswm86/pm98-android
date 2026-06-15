// FUN_00539140  entry=00539140  size=1748 bytes
// callers/callees expanded one level from seeds

void __thiscall FUN_00539140(int param_1,undefined4 param_2,int param_3,uint param_4)

{
  char cVar1;
  int iVar2;
  undefined1 *puVar3;
  uint uVar4;
  uint uVar5;
  undefined1 *puVar6;
  char *pcVar7;
  char *pcVar8;
  undefined4 local_108;
  undefined4 local_104;
  char local_100 [256];
  
  if (param_4 == 0) {
    puVar6 = &DAT_00666f70;
    puVar3 = &DAT_00666f70;
  }
  else {
    if (param_4 < DAT_0066c150) {
      iVar2 = *(int *)(DAT_0066c158 + param_4 * 4);
    }
    else {
      iVar2 = 0;
    }
    puVar3 = *(undefined1 **)(iVar2 + 4);
    puVar6 = *(undefined1 **)(*(int *)(param_1 + 18000 + param_3 * 4) + 4);
  }
  local_104 = *(undefined4 *)(param_1 + 0x192c);
  local_100[0] = '\0';
  *(undefined1 *)(param_1 + 0x1928) = 1;
  *(undefined1 *)(param_1 + 0x1929) = 1;
  switch(param_2) {
  case 1:
    local_108 = 0x5f00;
    pcVar8 = s_Foul_by__s___s__0065cf68;
    break;
  case 2:
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Free_kick_taken_by__s_0065cf50;
    goto LAB_00539333;
  case 3:
    local_108 = 0x5f00;
    pcVar8 = s_Yellow_card___s___s__0065cf38;
    break;
  case 4:
    local_108 = 0xaa;
    pcVar8 = s__s___s__sent_off_0065cf24;
    break;
  case 5:
    local_108 = 0xaa;
    pcVar8 = s__s___s__sent_off_0065cf24;
    break;
  case 6:
    local_108 = 0xaa;
    pcVar8 = s__s___s___injured_0065cf10;
    break;
  case 7:
    local_108 = 0xff;
    pcVar8 = s_Goal_by__s___s__0065cf00;
    break;
  case 8:
    local_108 = 0xff;
    pcVar8 = s_Goal_by__s___s___o_g___0065cee8;
    break;
  case 9:
    local_108 = 0x5f00;
    pcVar8 = s_Penalty_conceded_by__s___s__0065cecc;
    break;
  case 10:
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Penalty_taken_by__s_0065ceb8;
LAB_00539333:
    local_104 = 0xbe0000;
    local_108 = local_104;
    sprintf(local_100,pcVar8,puVar3);
    local_104 = 0;
    goto switchD_005391b5_default;
  case 0xb:
    local_108 = 0x52;
    pcVar8 = s__s___s__offside_0065cea8;
    break;
  case 0xc:
    local_108 = 0x5f00;
    sprintf(local_100,s_Corner_to__s_0065ce98,puVar6);
    goto switchD_005391b5_default;
  case 0xd:
    local_104 = 0xbe0000;
    *(undefined1 *)(param_1 + 0x1929) = 0;
    local_108 = 0xbe0000;
    sprintf(local_100,s_Corner_taken_by__s_0065ce84,puVar3);
    local_104 = 0;
    goto switchD_005391b5_default;
  case 0xe:
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Ball_cleared_by__s___s__0065ce6c;
    goto LAB_0053942d;
  case 0xf:
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Shot_saved_by__s___s__0065ce54;
LAB_0053942d:
    local_104 = 0x646464;
    local_108 = local_104;
    sprintf(local_100,pcVar8,puVar3,puVar6);
    local_104 = 0;
    goto switchD_005391b5_default;
  case 0x10:
    *(undefined1 *)(param_1 + 0x1929) = 0;
    local_108 = 0x646464;
    pcVar8 = s_Cross_by__s___s__0065ce40;
    break;
  case 0x11:
    *(undefined1 *)(param_1 + 0x1929) = 0;
    local_108 = 0x646464;
    pcVar8 = s_Good_run_by__s___s__0065ce2c;
    break;
  case 0x12:
    *(undefined1 *)(param_1 + 0x1929) = 0;
    local_108 = 0x646464;
    pcVar8 = s_Bad_challenge_by__s___s__0065ce10;
    break;
  case 0x13:
    local_108 = 0x646464;
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Good_defending_by__s___s__0065cdf4;
    break;
  case 0x14:
    local_108 = 0x646464;
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Good_tackle_by__s___s__0065cddc;
    break;
  case 0x15:
    local_108 = 0x646464;
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Shot_by__s___s__0065cdcc;
    break;
  case 0x16:
    local_108 = 0x646464;
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Header_by__s___s__0065cdb8;
    break;
  case 0x17:
    local_108 = 0x646464;
    uVar4 = 0xffffffff;
    pcVar8 = s_Shot_was_way_off_target_0065cd9c;
    do {
      pcVar7 = pcVar8;
      if (uVar4 == 0) break;
      uVar4 = uVar4 - 1;
      pcVar7 = pcVar8 + 1;
      cVar1 = *pcVar8;
      pcVar8 = pcVar7;
    } while (cVar1 != '\0');
    uVar4 = ~uVar4;
    local_104 = 0;
    pcVar8 = pcVar7 + -uVar4;
    pcVar7 = local_100;
    for (uVar5 = uVar4 >> 2; uVar5 != 0; uVar5 = uVar5 - 1) {
      *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
      pcVar8 = pcVar8 + 4;
      pcVar7 = pcVar7 + 4;
    }
    for (uVar4 = uVar4 & 3; uVar4 != 0; uVar4 = uVar4 - 1) {
      *pcVar7 = *pcVar8;
      pcVar8 = pcVar8 + 1;
      pcVar7 = pcVar7 + 1;
    }
    goto switchD_005391b5_default;
  case 0x18:
    local_108 = 0x646464;
    uVar4 = 0xffffffff;
    pcVar8 = s_Shot_was_just_wide_0065cd84;
    do {
      pcVar7 = pcVar8;
      if (uVar4 == 0) break;
      uVar4 = uVar4 - 1;
      pcVar7 = pcVar8 + 1;
      cVar1 = *pcVar8;
      pcVar8 = pcVar7;
    } while (cVar1 != '\0');
    uVar4 = ~uVar4;
    local_104 = 0;
    pcVar8 = pcVar7 + -uVar4;
    pcVar7 = local_100;
    for (uVar5 = uVar4 >> 2; uVar5 != 0; uVar5 = uVar5 - 1) {
      *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
      pcVar8 = pcVar8 + 4;
      pcVar7 = pcVar7 + 4;
    }
    for (uVar4 = uVar4 & 3; uVar4 != 0; uVar4 = uVar4 - 1) {
      *pcVar7 = *pcVar8;
      pcVar8 = pcVar8 + 1;
      pcVar7 = pcVar7 + 1;
    }
    goto switchD_005391b5_default;
  case 0x19:
    local_108 = 0x646464;
    uVar4 = 0xffffffff;
    pcVar8 = s_Shot_was_just_over_0065cd6c;
    do {
      pcVar7 = pcVar8;
      if (uVar4 == 0) break;
      uVar4 = uVar4 - 1;
      pcVar7 = pcVar8 + 1;
      cVar1 = *pcVar8;
      pcVar8 = pcVar7;
    } while (cVar1 != '\0');
    uVar4 = ~uVar4;
    local_104 = 0;
    pcVar8 = pcVar7 + -uVar4;
    pcVar7 = local_100;
    for (uVar5 = uVar4 >> 2; uVar5 != 0; uVar5 = uVar5 - 1) {
      *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
      pcVar8 = pcVar8 + 4;
      pcVar7 = pcVar7 + 4;
    }
    for (uVar4 = uVar4 & 3; uVar4 != 0; uVar4 = uVar4 - 1) {
      *pcVar7 = *pcVar8;
      pcVar8 = pcVar8 + 1;
      pcVar7 = pcVar7 + 1;
    }
    goto switchD_005391b5_default;
  case 0x1a:
    local_108 = 0x646464;
    uVar4 = 0xffffffff;
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Shot_hit_crossbar_0065cd54;
    do {
      pcVar7 = pcVar8;
      if (uVar4 == 0) break;
      uVar4 = uVar4 - 1;
      pcVar7 = pcVar8 + 1;
      cVar1 = *pcVar8;
      pcVar8 = pcVar7;
    } while (cVar1 != '\0');
    uVar4 = ~uVar4;
    local_104 = 0;
    pcVar8 = pcVar7 + -uVar4;
    pcVar7 = local_100;
    for (uVar5 = uVar4 >> 2; uVar5 != 0; uVar5 = uVar5 - 1) {
      *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
      pcVar8 = pcVar8 + 4;
      pcVar7 = pcVar7 + 4;
    }
    for (uVar4 = uVar4 & 3; uVar4 != 0; uVar4 = uVar4 - 1) {
      *pcVar7 = *pcVar8;
      pcVar8 = pcVar8 + 1;
      pcVar7 = pcVar7 + 1;
    }
    goto switchD_005391b5_default;
  case 0x1b:
    local_108 = 0x646464;
    uVar4 = 0xffffffff;
    *(undefined1 *)(param_1 + 0x1929) = 0;
    pcVar8 = s_Shot_rebounded_off_the_post_0065cd34;
    do {
      pcVar7 = pcVar8;
      if (uVar4 == 0) break;
      uVar4 = uVar4 - 1;
      pcVar7 = pcVar8 + 1;
      cVar1 = *pcVar8;
      pcVar8 = pcVar7;
    } while (cVar1 != '\0');
    uVar4 = ~uVar4;
    local_104 = 0;
    pcVar8 = pcVar7 + -uVar4;
    pcVar7 = local_100;
    for (uVar5 = uVar4 >> 2; uVar5 != 0; uVar5 = uVar5 - 1) {
      *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
      pcVar8 = pcVar8 + 4;
      pcVar7 = pcVar7 + 4;
    }
    for (uVar4 = uVar4 & 3; uVar4 != 0; uVar4 = uVar4 - 1) {
      *pcVar7 = *pcVar8;
      pcVar8 = pcVar8 + 1;
      pcVar7 = pcVar7 + 1;
    }
    goto switchD_005391b5_default;
  case 0x1c:
    *(undefined1 *)(param_1 + 0x1928) = 0;
    *(undefined4 *)(param_1 + 0x1940) = 2;
    pcVar8 = s_Halftime_0065cd28;
    goto LAB_005397c1;
  case 0x1d:
    *(undefined1 *)(param_1 + 0x1928) = 0;
    *(undefined4 *)(param_1 + 0x1940) = 3;
    pcVar8 = s_End_of_the_second_half_0065cd10;
    goto LAB_005397c1;
  case 0x1e:
    *(undefined1 *)(param_1 + 0x1928) = 0;
    *(undefined4 *)(param_1 + 0x1940) = 4;
    pcVar8 = s_End_of_first_half_of_extra_time_0065ccf0;
    goto LAB_005397c1;
  case 0x1f:
    if (*(int *)(param_1 + 0x1940) == 4) {
      uVar4 = 0xffffffff;
      pcVar8 = s_End_of_second_half_of_extra_time_0065cccc;
      do {
        pcVar7 = pcVar8;
        if (uVar4 == 0) break;
        uVar4 = uVar4 - 1;
        pcVar7 = pcVar8 + 1;
        cVar1 = *pcVar8;
        pcVar8 = pcVar7;
      } while (cVar1 != '\0');
      uVar4 = ~uVar4;
      pcVar8 = pcVar7 + -uVar4;
      pcVar7 = local_100;
      for (uVar5 = uVar4 >> 2; uVar5 != 0; uVar5 = uVar5 - 1) {
        *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
        pcVar8 = pcVar8 + 4;
        pcVar7 = pcVar7 + 4;
      }
      for (uVar4 = uVar4 & 3; uVar4 != 0; uVar4 = uVar4 - 1) {
        *pcVar7 = *pcVar8;
        pcVar8 = pcVar8 + 1;
        pcVar7 = pcVar7 + 1;
      }
    }
    *(undefined1 *)(param_1 + 0x1928) = 0;
    *(undefined4 *)(param_1 + 0x1940) = 5;
    local_108 = 0;
    goto switchD_005391b5_default;
  case 0x20:
    *(undefined1 *)(param_1 + 0x1928) = 0;
    *(undefined1 *)(param_1 + 0x1929) = 0;
    *(undefined4 *)(param_1 + 0x1940) = 6;
    pcVar8 = s_Full_time_0065ccc0;
LAB_005397c1:
    local_108 = 0;
    uVar4 = 0xffffffff;
    do {
      pcVar7 = pcVar8;
      if (uVar4 == 0) break;
      uVar4 = uVar4 - 1;
      pcVar7 = pcVar8 + 1;
      cVar1 = *pcVar8;
      pcVar8 = pcVar7;
    } while (cVar1 != '\0');
    uVar4 = ~uVar4;
    pcVar8 = pcVar7 + -uVar4;
    pcVar7 = local_100;
    for (uVar5 = uVar4 >> 2; uVar5 != 0; uVar5 = uVar5 - 1) {
      *(undefined4 *)pcVar7 = *(undefined4 *)pcVar8;
      pcVar8 = pcVar8 + 4;
      pcVar7 = pcVar7 + 4;
    }
    for (uVar4 = uVar4 & 3; uVar4 != 0; uVar4 = uVar4 - 1) {
      *pcVar7 = *pcVar8;
      pcVar8 = pcVar8 + 1;
      pcVar7 = pcVar7 + 1;
    }
  default:
    goto switchD_005391b5_default;
  }
  sprintf(local_100,pcVar8,puVar3,puVar6);
switchD_005391b5_default:
  if (local_100[0] != '\0') {
    FUN_005387d0(1);
    FUN_00539d70(local_104,local_100,&local_108);
  }
  return;
}



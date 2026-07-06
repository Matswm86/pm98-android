// FUN_00579460  entry=00579460  size=370 bytes

void __thiscall FUN_00579460(int *param_1,int param_2)

{
  char cVar1;
  void *pvVar2;
  undefined4 *puVar3;
  uint uVar4;
  uint uVar5;
  undefined4 *puVar6;
  char *pcVar7;
  undefined4 local_204;
  CHAR local_200 [512];
  
  pvVar2 = (void *)param_1[2];
  *param_1 = param_2;
  if ((pvVar2 != (void *)0x0) && ((param_1[4] == 0 || (pvVar2 != *(void **)(param_1[4] + 4))))) {
    operator_delete(pvVar2);
  }
  pvVar2 = (void *)param_1[3];
  if ((pvVar2 != (void *)0x0) && ((param_1[4] == 0 || (pvVar2 != *(void **)(param_1[4] + 8))))) {
    operator_delete(pvVar2);
  }
  if (param_2 == 0) {
    param_1[2] = *(int *)(param_1[4] + 4);
    param_1[3] = *(int *)(param_1[4] + 8);
    return;
  }
  if (param_2 == 9) {
    uVar4 = 0xffffffff;
    pcVar7 = *(char **)(param_1[4] + 4);
    do {
      if (uVar4 == 0) break;
      uVar4 = uVar4 - 1;
      cVar1 = *pcVar7;
      pcVar7 = pcVar7 + 1;
    } while (cVar1 != '\0');
    uVar4 = ~uVar4;
    puVar3 = operator_new(uVar4);
    if (puVar3 == (undefined4 *)0x0) {
      local_204 = 0xffff0002;
      lstrcpyA(local_200,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
    }
    param_1[2] = (int)puVar3;
    puVar6 = *(undefined4 **)(param_1[4] + 4);
    for (uVar5 = uVar4 >> 2; uVar5 != 0; uVar5 = uVar5 - 1) {
      *puVar3 = *puVar6;
      puVar6 = puVar6 + 1;
      puVar3 = puVar3 + 1;
    }
    for (uVar4 = uVar4 & 3; uVar4 != 0; uVar4 = uVar4 - 1) {
      *(undefined1 *)puVar3 = *(undefined1 *)puVar6;
      puVar6 = (undefined4 *)((int)puVar6 + 1);
      puVar3 = (undefined4 *)((int)puVar3 + 1);
    }
    uVar4 = 0xffffffff;
    pcVar7 = *(char **)(param_1[4] + 8);
    do {
      if (uVar4 == 0) break;
      uVar4 = uVar4 - 1;
      cVar1 = *pcVar7;
      pcVar7 = pcVar7 + 1;
    } while (cVar1 != '\0');
    uVar4 = ~uVar4;
    puVar3 = operator_new(uVar4);
    if (puVar3 == (undefined4 *)0x0) {
      local_204 = 0xffff0002;
      lstrcpyA(local_200,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&local_204,(ThrowInfo *)&DAT_0063ac98);
    }
    param_1[3] = (int)puVar3;
    puVar6 = *(undefined4 **)(param_1[4] + 8);
    for (uVar5 = uVar4 >> 2; uVar5 != 0; uVar5 = uVar5 - 1) {
      *puVar3 = *puVar6;
      puVar6 = puVar6 + 1;
      puVar3 = puVar3 + 1;
    }
    for (uVar4 = uVar4 & 3; uVar4 != 0; uVar4 = uVar4 - 1) {
      *(undefined1 *)puVar3 = *(undefined1 *)puVar6;
      puVar6 = (undefined4 *)((int)puVar6 + 1);
      puVar3 = (undefined4 *)((int)puVar3 + 1);
    }
  }
  else {
    param_1[2] = 0;
    param_1[3] = 0;
    FUN_005793f0();
  }
  pvVar2 = (void *)param_1[4];
  if (pvVar2 != (void *)0x0) {
    FUN_00579a00();
    operator_delete(pvVar2);
  }
  param_1[4] = 0;
  return;
}



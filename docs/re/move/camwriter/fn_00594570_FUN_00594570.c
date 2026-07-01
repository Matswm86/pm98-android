// FUN_00594570  entry=00594570  size=349 bytes

void __thiscall FUN_00594570(int param_1,char param_2)

{
  int *piVar1;
  bool bVar2;
  char cVar3;
  int iVar4;
  int iVar5;
  void *_Dst;
  int iVar6;
  undefined4 *puVar7;
  int local_8;
  int local_4;
  
  if (DAT_006d31c4 == '\0') {
    iVar6 = 0;
    local_8 = 0;
    if (0 < *(int *)(param_1 + 0x1a28)) {
      piVar1 = (int *)(param_1 + 0x1a24);
      local_4 = 0;
      do {
        puVar7 = (undefined4 *)(*piVar1 + iVar6);
        if (param_2 == '\0') {
          cVar3 = FUN_005943d0();
          if ((cVar3 == '\0') && (cVar3 = FUN_005943b0(), cVar3 == '\0')) {
            bVar2 = false;
          }
          else {
            bVar2 = true;
          }
          if ((bVar2) ||
             ((*(int *)(param_1 + 0x448) == 0 &&
              (iVar5 = puVar7[3], puVar7[3] = iVar5 + -1, iVar5 + -1 < 1)))) goto LAB_005945fa;
        }
        else {
LAB_005945fa:
          FUN_00594410();
          FUN_004511d0(*puVar7,puVar7[1],puVar7[2]);
          local_8 = local_8 + -1;
          iVar4 = local_4 + 0xfffffff;
          local_4 = local_4 + -0xfffffff;
          iVar5 = iVar6 + 0x10;
          _Dst = (void *)(iVar6 + *piVar1);
          iVar6 = iVar6 + -0x10;
          memmove(_Dst,(void *)(iVar5 + *piVar1),(iVar4 + *(int *)(param_1 + 0x1a28)) * 0x10);
          iVar5 = *(int *)(param_1 + 0x1a28) + -1;
          *(int *)(param_1 + 0x1a28) = iVar5;
          FUN_005bbf10(piVar1,iVar5 * 0x10);
        }
        local_8 = local_8 + 1;
        local_4 = local_4 + 0xfffffff;
        iVar6 = iVar6 + 0x10;
      } while (local_8 < *(int *)(param_1 + 0x1a28));
    }
    if (param_2 != '\0') {
      *(undefined4 *)(param_1 + 0x1a2c) = 0;
      *(undefined4 *)(param_1 + 0x1a30) = 0;
      return;
    }
    if (*(int *)(param_1 + 0x1a30) != 0) {
      *(int *)(param_1 + 0x1a30) = *(int *)(param_1 + 0x1a30) + -1;
    }
  }
  return;
}



// FUN_005f6e70  entry=005f6e70  size=498 bytes
// callers/callees expanded one level from seeds

/* WARNING: Removing unreachable block (ram,0x005f6fc9) */
/* WARNING: Removing unreachable block (ram,0x005f6fd5) */
/* WARNING: Removing unreachable block (ram,0x005f6fda) */

void __thiscall FUN_005f6e70(int *param_1,undefined4 param_2)

{
  undefined1 *puVar1;
  char cVar2;
  int iVar3;
  int iVar4;
  int iVar5;
  undefined1 *local_10c;
  int local_108;
  undefined4 local_104;
  int local_100;
  undefined1 local_fc [240];
  void *local_c;
  undefined1 *puStack_8;
  uint local_4;
  
  local_4 = 0xffffffff;
  puStack_8 = &LAB_00622756;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  FUN_005f6410(param_2);
  local_10c = local_fc;
  local_108 = 0;
  local_104 = 0;
  local_4 = 1;
  iVar3 = param_1[1] + -1;
  local_100 = 0;
  iVar5 = param_1[1] / 2;
  if (-1 < iVar3) {
    do {
      if ((param_1[1] <= iVar3) || (cVar2 = FUN_005f6e50(local_10c), cVar2 == '\0')) break;
      cVar2 = FUN_005f6e20(&local_10c);
      if (cVar2 == '\0') {
        iVar3 = iVar5 + -1;
      }
      else {
        local_100 = iVar5 + 1;
      }
      iVar5 = (local_100 + 1 + iVar3) / 2;
    } while (local_100 <= iVar3);
  }
  if (iVar5 < param_1[1]) {
    iVar4 = iVar5 * 0xc;
    iVar3 = lstrcmpA((LPCSTR)(*(int *)(*param_1 + iVar4) + 0x4c),local_10c + 0x4c);
    if ((iVar3 == 0) &&
       (iVar3 = *(int *)(*param_1 + iVar4 + 8) + -1, *(int *)(*param_1 + iVar4 + 8) = iVar3,
       iVar3 < 0)) {
      if (*param_1 + iVar4 != 0) {
        FUN_005f7100();
      }
      memmove((void *)(*param_1 + iVar4),(void *)((iVar5 + 1) * 0xc + *param_1),
              param_1[1] * 0xc + (iVar5 + 1) * -0xc);
      iVar3 = param_1[1];
      param_1[1] = iVar3 + -1;
      FUN_005bbf10(param_1,(iVar3 + -1) * 0xc);
      if (param_1[1] == 0) {
        param_1[1] = -1;
        if (*param_1 != 0) {
          FUN_005bbed0(*param_1);
          *param_1 = 0;
        }
        param_1[1] = 0;
      }
    }
  }
  puVar1 = local_10c;
  local_4 = local_4 & 0xffffff00;
  if ((local_108 != 0) && (local_10c != (undefined1 *)0x0)) {
    FUN_005f64b0();
    operator_delete(puVar1);
  }
  local_10c = (undefined1 *)0x0;
  local_4 = 0xffffffff;
  FUN_005f64b0();
  ExceptionList = local_c;
  return;
}



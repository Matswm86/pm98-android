// FUN_00545180  entry=00545180  size=875 bytes

int __thiscall FUN_00545180(int param_1,undefined4 param_2)

{
  int iVar1;
  HRSRC hResInfo;
  HGLOBAL pvVar2;
  undefined4 uVar3;
  void *pvVar4;
  int *piVar5;
  int iVar6;
  undefined1 *puVar7;
  undefined4 uVar8;
  undefined4 uVar9;
  uint uVar10;
  char *pcVar11;
  uint *local_464;
  CRect local_440 [48];
  char acStack_410 [256];
  char local_310 [256];
  undefined4 uStack_210;
  CHAR aCStack_20c [512];
  void *local_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_0061b57d;
  local_c = ExceptionList;
  ExceptionList = &local_c;
  iVar1 = FUN_004fa840(param_2);
  if (iVar1 != 0) {
    DAT_0066c0c0 = 0;
    local_310[0] = '\0';
    hResInfo = FindResourceA((HMODULE)0x0,(LPCSTR)0x1,(LPCSTR)0x10);
    if ((hResInfo != (HRSRC)0x0) &&
       (pvVar2 = LoadResource((HMODULE)0x0,hResInfo), pvVar2 != (HGLOBAL)0x0)) {
      sprintf(local_310,s_F_u__u_0065da48);
    }
    if (local_310[0] != '\0') {
      iVar6 = *(int *)(param_1 + 0x1928);
      FUN_00436270(0xffffffff);
      uVar9 = 0;
      pcVar11 = local_310;
      uVar8 = 0x820;
      uVar3 = CRect::CRect(local_440,0,0x1cc,0x28,0x1e0);
      (**(code **)(iVar6 + 0xc0))(param_1,uVar3,pcVar11,uVar8,uVar9);
      FUN_005beae0();
      FUN_00468c70();
    }
    *(char **)(param_1 + 0xccc) = s_INFOFUT_if5mepri_htm_0065da30;
    if (DAT_00633588 != 0) {
      local_464 = (uint *)&DAT_00633588;
      do {
        pvVar4 = operator_new(0x418);
        uStack_4 = 0;
        if (pvVar4 == (void *)0x0) {
          piVar5 = (int *)0x0;
        }
        else {
          piVar5 = (int *)FUN_005c7e20();
        }
        uStack_4 = 0xffffffff;
        if (piVar5 == (int *)0x0) {
          uStack_210 = 0xffff0002;
          lstrcpyA(aCStack_20c,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
          _CxxThrowException(&uStack_210,(ThrowInfo *)&DAT_0063ac98);
        }
        if ((*local_464 < 20000) || (0x4e36 < *local_464)) {
          iVar6 = *piVar5;
          FUN_00436270(0xffffffff);
          uVar10 = *local_464;
          uVar9 = 0x800;
          puVar7 = &DAT_00666f70;
          uVar3 = FUN_00436fb0(local_464[3],local_464[4]);
          uVar8 = FUN_00436fb0(local_464[1],local_464[2]);
          uVar3 = FUN_00436fd0(uVar8,uVar3);
          (**(code **)(iVar6 + 0xc0))(param_1,uVar3,puVar7,uVar9,uVar10);
          pcVar11 = s_RECURSOS_PREMIER_ICONOS__s_0065d9f8;
        }
        else {
          iVar6 = *piVar5;
          FUN_00436270(0xffffffff);
          uVar10 = *local_464;
          uVar9 = 0x800;
          puVar7 = &DAT_00666f70;
          uVar3 = FUN_00436fb0(local_464[3],local_464[4]);
          uVar8 = FUN_00436fb0(local_464[1],local_464[2] - 0x14);
          uVar3 = FUN_00436fd0(uVar8,uVar3);
          (**(code **)(iVar6 + 0xc0))(param_1,uVar3,puVar7,uVar9,uVar10);
          pcVar11 = s_RECURSOS_PREMIER_SININFO__s_0065da14;
        }
        sprintf(acStack_410,pcVar11);
        FUN_005c06d0(acStack_410,1,0);
        if (local_464[10] != 0) {
          sprintf(acStack_410,s_RECURSOS_PREMIER_ICONOS__s_0065d9f8);
          FUN_005c06d0(acStack_410,0,0);
          piVar5[0x2b] = piVar5[0x2b] & 0xfffff7ff;
        }
        FUN_005beb60();
        FUN_005beb90();
        iVar6 = FUN_005e4670();
        piVar5[0xeb] = iVar6;
        iVar6 = FUN_005e4670();
        piVar5[0xe6] = iVar6;
        FUN_005c5d30();
        local_464 = local_464 + 0xb;
      } while (*local_464 != 0);
    }
  }
  ExceptionList = local_c;
  return iVar1;
}



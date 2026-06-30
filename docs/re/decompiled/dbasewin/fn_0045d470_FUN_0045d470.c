// FUN_0045d470  entry=0045d470  size=387 bytes

uint __thiscall
FUN_0045d470(void *this,int param_1,int *param_2,char *param_3,uint param_4,undefined4 param_5,
            undefined4 param_6,int param_7)

{
  CWnd CVar1;
  undefined3 extraout_var;
  undefined4 *puVar3;
  int iVar4;
  int iVar5;
  undefined4 uStack_210;
  CHAR aCStack_20c [512];
  void *pvStack_c;
  undefined1 *puStack_8;
  undefined4 uStack_4;
  uint uVar2;
  
  uStack_4 = 0xffffffff;
  puStack_8 = &LAB_00482dbe;
  pvStack_c = ExceptionList;
  ExceptionList = &pvStack_c;
  if ((DAT_00501da8 != (int *)0x0) && (ExceptionList = &pvStack_c, (param_4 & 0x3000) != 0)) {
    ExceptionList = &pvStack_c;
    (**(code **)(*DAT_00501da8 + 0xf0))(0xffffffff);
    DAT_00501da8 = (int *)0x0;
  }
  iVar4 = param_7;
  iVar5 = param_7;
  FUN_004042e0(&stack0xfffffdd8,&param_6);
  CVar1 = FUN_00454200(this,param_1,param_2,param_3,param_4,param_5,iVar4,iVar5);
  uVar2 = CONCAT31(extraout_var,CVar1);
  if ((uVar2 != 0) && ((param_4 & 4) != 0)) {
    *(void **)((int)this + 600) = this;
    iVar4 = *(int *)((int)this + 0x80) - *(int *)((int)this + 0x78);
    iVar5 = *(int *)((int)this + 0x84) - *(int *)((int)this + 0x7c);
    *(undefined4 *)((int)this + 0x3fc) = 0;
    *(undefined4 *)((int)this + 0x400) = 0;
    *(int *)((int)this + 0x404) = iVar4;
    *(int *)((int)this + 0x408) = iVar5;
    *(undefined4 *)((int)this + 0x40c) = 0;
    *(undefined4 *)((int)this + 0x410) = 0;
    *(int *)((int)this + 0x414) = iVar4;
    *(int *)((int)this + 0x418) = iVar5;
    puVar3 = operator_new(0x278);
    uStack_4 = 0;
    if (puVar3 == (undefined4 *)0x0) {
      puVar3 = (undefined4 *)0x0;
    }
    else {
      puVar3 = FUN_00451be0(puVar3);
    }
    uStack_4 = 0xffffffff;
    if (puVar3 == (undefined4 *)0x0) {
      uStack_210 = 0xffff0002;
      lstrcpyA(aCStack_20c,&DAT_00496cd0);
                    /* WARNING: Subroutine does not return */
      _CxxThrowException(&uStack_210,(ThrowInfo *)&DAT_0048b400);
    }
    *(undefined4 **)((int)this + 0x3f4) = puVar3;
    uVar2 = (uint)(puVar3 != (undefined4 *)0x0);
  }
  ExceptionList = pvStack_c;
  return uVar2;
}



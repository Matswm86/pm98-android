// FUN_004f82ec  entry=004f82ec  size=325 bytes

int FUN_004f82ec(void)

{
  bool bVar1;
  undefined4 uVar2;
  int _FileHandle;
  long lVar3;
  uint uVar4;
  char cStack00000010;
  char cStack00000011;
  char cStack00000012;
  char cStack00000013;
  char cStack00000014;
  char cStack00000015;
  undefined4 in_stack_00000110;
  
  bVar1 = true;
  uVar4 = 0;
  uVar2 = FUN_005ec200(0x658a60);
  sprintf(&stack0x00000010,&DAT_00654c38,uVar2);
  _FileHandle = _open(&stack0x00000010,0x8000);
  if (_FileHandle != -1) {
    lVar3 = _filelength(_FileHandle);
    _lseek(_FileHandle,0xecbf,1);
    _read(_FileHandle,&stack0x00000010,6);
    if (((((cStack00000010 == 'D') && (cStack00000011 == '.')) && (cStack00000012 == 'G')) &&
        ((cStack00000013 == '.' && (cStack00000014 == 'C')))) && (cStack00000015 == '.')) {
      bVar1 = false;
    }
    else {
      bVar1 = true;
    }
    _close(_FileHandle);
    _FileHandle = (lVar3 - 6U) * 0x7f086a89;
    uVar4 = (lVar3 - 6U) / 0x101f2f;
  }
  if ((!bVar1) && (uVar4 == 0x12a)) {
    return _FileHandle;
  }
  FUN_004fa540(1);
  sprintf(&stack0x00000010,PTR_DAT_00662e40,PTR_s_PREMIER_MANAGER_98_00662da0);
  FUN_005e5050(DAT_00674ea0,PTR_s_PREMIER_MANAGER_98_00662da0,&stack0x00000010,1,0,0);
  in_stack_00000110 = 0x4e3a;
  lstrcpyA(&stack0x00000114,&DAT_00666f70);
                    /* WARNING: Subroutine does not return */
  _CxxThrowException(&stack0x00000110,(ThrowInfo *)&DAT_0063ac98);
}



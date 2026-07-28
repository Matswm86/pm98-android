// FUN_005cb390  entry=005cb390  size=135 bytes

undefined1 __fastcall FUN_005cb390(int param_1)

{
  bool bVar1;
  int iVar2;
  
  if (*(HDC *)(param_1 + 0x40) != (HDC)0x0) {
    if (*(HGDIOBJ *)(param_1 + 0x44) != (HGDIOBJ)0x0) {
      SelectObject(*(HDC *)(param_1 + 0x40),*(HGDIOBJ *)(param_1 + 0x44));
      *(undefined4 *)(param_1 + 0x44) = 0;
    }
    if ((DAT_00674804 < 1) || (*(int *)(DAT_00674800 + 0x18 + DAT_00674c2c * 0x134) == 0)) {
      bVar1 = false;
    }
    else {
      bVar1 = true;
    }
    if (bVar1) {
      iVar2 = (**(code **)(**(int **)(param_1 + 4) + 0x68))
                        (*(int **)(param_1 + 4),*(undefined4 *)(param_1 + 0x40));
      if (-1 < iVar2) {
        *(undefined4 *)(param_1 + 0x40) = 0;
        return 1;
      }
    }
    *(undefined4 *)(param_1 + 0x40) = 0;
  }
  return 0;
}



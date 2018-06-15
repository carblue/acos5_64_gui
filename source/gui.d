/*
 * Written in the D programming language, part of package acos5_64_gui.
 * gui.d: Graphical User Interface file, based on IUP
 *
 * Copyright (C) 2018- : Carsten Blüggel <bluecars@posteo.eu>
 *
 * This application is free software; You can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation,
 * version 2.0 of the License.
 *
 * This software is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this application; if not, write to the Free Software
 * Foundation, 51 Franklin Street, Fifth Floor, Boston, MA 02110-1335  USA
 */

module gui;

import std.stdio : write, writeln, writefln, stdout;
import std.algorithm.comparison : among;

import iup.iup_plusD;

import libintl : _, __;

import callbacks;
import generateKeyPair_RSA;


private Hbox create_cryptoki_slot_tokeninfo_tab() {
    Control[]  child_array1, child_array2;
    Matrix     matrix;
    Text       text;
//    Vbox       vbox1, vbox2;
//    List       list;

    matrix = new Matrix("slot_token");
    with (matrix) {
        SetInteger(IUP_NUMLIN,         41);
        SetInteger(IUP_NUMLIN_VISIBLE, 41);
        SetInteger(IUP_NUMCOL,          1);
        SetInteger(IUP_NUMCOL_VISIBLE,  1);
        SetAttribute(IUP_RESIZEMATRIX, IUP_YES);
//      SetAttribute("LIMITEXPAND",  IUP_YES);
        SetAttribute(IUP_READONLY,     IUP_YES);
//      SetAttribute("FLATSCROLLBAR",     IUP_YES);
//      SetAttribute("EDITNEXT",     "COL");
        SetIntegerId(IUP_WIDTH,   0,    220);
        SetIntegerId(IUP_WIDTH,   1,    130);
        SetInteger(IUP_HEIGHTDEF,  5);

        SetAttributeId2("", 0,  1,   __("value")); // SetAttributeId2("", 1,  1, "");

        SetAttributeId2("",  1,  0,   "Cryptoki version"); //  SetAttributeId2("",  7,  1, "CKF_REMOVABLE_DEVICE");
        SetAttributeId2("",  2,  0,   __("Cryptoki manufacturerID")); //         SetAttributeId2("",  3,  1, "-");
        SetAttributeId2("",  3,  0,   "Cryptoki flags bitfield"); //  SetAttributeId2("",  7,  1, "CKF_REMOVABLE_DEVICE");
        SetAttributeId2("",  4,  0,   "Cryptoki libraryDescription"); //         SetAttributeId2("",  3,  1, "-");
        SetAttributeId2("",  5,  0,   "Cryptoki libraryVersion"); //  SetAttributeId2("",  7,  1, "CKF_REMOVABLE_DEVICE");

        SetAttributeId2("",  6,  0,   "Slot id"); //                  SetAttributeId2("",  1,  1, "-");
        SetAttributeId2("",  7,  0,   __("Slot description")); //        SetAttributeId2("",  2,  1, "-");
        SetAttributeId2("",  8,  0,   __("Slot manufacturerID")); //         SetAttributeId2("",  3,  1, "-");
        SetAttributeId2("",  9,  0,   "Slot flag CKF_TOKEN_PRESENT"); //           SetAttributeId2("",  4,  1, "CKF_REMOVABLE_DEVICE");
        SetAttributeId2("", 10,  0,   "Slot flag CKF_REMOVABLE_DEVICE"); //           SetAttributeId2("",  5,  1, "CKF_REMOVABLE_DEVICE");
        SetAttributeId2("", 11,  0,   "Slot flag CKF_HW_SLOT"); //           SetAttributeId2("",  6,  1, "CKF_REMOVABLE_DEVICE");
        SetAttributeId2("", 12,  0,   "Slot hardware/firmware version"); //  SetAttributeId2("",  7,  1, "CKF_REMOVABLE_DEVICE");

        SetAttributeId2("", 13,  0,   __("Token label")); //              SetAttributeId2("",  8,  1, "-");
        SetAttributeId2("", 14,  0,   __("Token manufacturer")); //       SetAttributeId2("",  9,  1, "-");
        SetAttributeId2("", 15,  0,   "Token model"); //              SetAttributeId2("", 10,  1, "-");
        SetAttributeId2("", 16,  0,   "Token serialnr"); //           SetAttributeId2("", 11,  1, "-");

        SetAttributeId2("", 17,  0,   "Token flags bitfield (summary, below the details)"); //        SetAttributeId2("", 12,  1, "-");
        SetAttributeId2("", 18,  0,   "Token flag CKF_RNG"); //      SetAttributeId2("", 13,  1, "-");
        SetAttributeId2("", 19,  0,   "Token flag CKF_WRITE_PROTECTED"); //        SetAttributeId2("", 14,  1, "-");
        SetAttributeId2("", 20,  0,   "Token flag CKF_LOGIN_REQUIRED"); //         SetAttributeId2("", 15,  1, "-");
        SetAttributeId2("", 21,  0,   "Token flag CKF_USER_PIN_INITIALIZED"); //           SetAttributeId2("", 16,  1, "-");

        SetAttributeId2("", 22,  0,   "Token flag CKF_PROTECTED_AUTHENTICATION_PATH"); //             SetAttributeId2("", 17,  1, "-");
        SetAttributeId2("", 23,  0,   "Token flag CKF_DUAL_CRYPTO_OPERATIONS"); //    SetAttributeId2("", 18,  1, "-");
        SetAttributeId2("", 24,  0,   "Token flag CKF_TOKEN_INITIALIZED"); //    SetAttributeId2("", 19,  1, "-");
        SetAttributeId2("", 25,  0,   "Token flag CKF_SECONDARY_AUTHENTICATION"); //      SetAttributeId2("", 20,  1, "-");

        SetAttributeId2("", 26,  0,   "Token flag CKF_USER_PIN_COUNT_LOW"); // SetAttributeId2("", 21,  1, "-");
        SetAttributeId2("", 27,  0,   "Token flag CKF_USER_PIN_FINAL_TRY"); //      SetAttributeId2("", 22,  1, "-");
        SetAttributeId2("", 28,  0,   "Token flag CKF_USER_PIN_LOCKED"); //      SetAttributeId2("", 23,  1, "-");
        SetAttributeId2("", 29,  0,   "Token flag CKF_USER_PIN_TO_BE_CHANGED"); //        SetAttributeId2("", 24,  1, "-");

        SetAttributeId2("", 30,  0,   "Token flag CKF_SO_PIN_COUNT_LOW"); //   SetAttributeId2("", 25,  1, "-");
        SetAttributeId2("", 31,  0,   "Token flag CKF_SO_PIN_FINAL_TRY"); //   SetAttributeId2("", 25,  1, "-");
        SetAttributeId2("", 32,  0,   "Token flag CKF_SO_PIN_LOCKED"); //   SetAttributeId2("", 25,  1, "-");
        SetAttributeId2("", 33,  0,   "Token flag CKF_SO_PIN_TO_BE_CHANGED"); //   SetAttributeId2("", 25,  1, "-");

        SetAttributeId2("", 34,  0,   "Token flag CKF_ERROR_STATE"); //   SetAttributeId2("", 25,  1, "-");

        SetAttributeId2("", 35,  0,   "Token SessionCount cur/max"); //   SetAttributeId2("", 25,  1, "-");
        SetAttributeId2("", 36,  0,   "Token RwSessionCount cur/max"); //   SetAttributeId2("", 25,  1, "-");
        SetAttributeId2("", 37,  0,   "Token PinLen min/max"); //   SetAttributeId2("", 25,  1, "-");
        SetAttributeId2("", 38,  0,   "Token PublicMemory free/total"); //   SetAttributeId2("", 25,  1, "-");
        SetAttributeId2("", 39,  0,   "Token PrivateMemory free/total"); //   SetAttributeId2("", 25,  1, "-");
        SetAttributeId2("", 40,  0,   "Token hardware/firmware version"); //  SetAttributeId2("",  7,  1, "CKF_REMOVABLE_DEVICE");
        SetAttributeId2("", 41,  0,   "Token utcTime"); //  SetAttributeId2("",  7,  1, "CKF_REMOVABLE_DEVICE");

        SetAttribute(IUP_TOGGLECENTERED,  IUP_YES);
        SetCallback(IUP_DROPCHECK_CB,  cast(Icallback) &slot_token_dropcheck_cb);
    }
    child_array1 ~= matrix;
    auto vbox1 = new Vbox(child_array1, FILL_TYPE.FILL_FRONT_AND_BACK);
    child_array2 ~= vbox1;

    text = new Text("cst_text");
    with (text) {
        SetInteger  (IUP_SIZE, 500);
        SetAttribute(IUP_MULTILINE, IUP_YES);
        SetInteger  (IUP_VISIBLELINES, 40);
        SetAttribute(IUP_WORDWRAP, IUP_YES);
    }
    child_array2 ~= text;

    auto hbox = new Hbox(child_array2, FILL_TYPE.FILL_FRONT_AND_BACK_AND_BETWEEN);
    hbox.SetAttribute(ICTL_TABTITLE, "Cryptoki/Slot/Token-Info");
    return hbox;
}

private Vbox create_opensc_conf_tab() {
    Control[] child_array;

    child_array ~= new Label(  "This page allows editing opensc.conf (and later acos5_64.profile). Root privileges will be required for storing"); // will be collected
    child_array ~= new Label(  "There are 2 modes how to handle Root privileges: Either enter admin password in this app, or in a shell for a command sudo patch -b /etc/opensc/opensc.conf conf.diff"); // will be collected

    auto vbox = new Vbox(new Vbox(child_array, FILL_TYPE.FILL_BETWEEN), new Fill);
    vbox.SetAttribute(ICTL_TABTITLE, "opensc.conf");
    return vbox;
}

private Hbox create_filesystem_tab() {
    Control[] child_array1, child_array2;
    auto tree_fs = new Tree("tree_fs");
    with (tree_fs) {
        SetAttribute(IUP_SHOWTOGGLE, IUP_YES);

        SetCallback(IUP_SELECTION_CB, cast(Icallback) &selectbranchleaf_cb);
        SetCallback(IUP_EXECUTELEAF_CB, cast(Icallback) &executeleaf_cb);
//      SetCallback("RENAME_CB", cast(Icallback) &rename_cb);
        SetCallback(IUP_BRANCHCLOSE_CB, cast(Icallback) &branchclose_cb);
        SetCallback(IUP_BRANCHOPEN_CB, cast(Icallback) &branchopen_cb);
//      SetCallback("DRAGDROP_CB", cast(Icallback) &dragdrop_cb);
//      SetCallback(IUP_RIGHTCLICK_CB, cast(Icallback) &rightclick_cb);
////    SetCallback(IUP_K_ANY, cast(Icallback) &k_any_cb);

//      SetAttribute("FONT","COURIER_NORMAL");
//      SetAttribute("CTRL",IUP_YES);
//      SetAttribute("SHIFT",IUP_YES);
//      SetAttribute("ADDEXPANDED", "NO");
//      SetAttribute("SHOWDRAGDROP", IUP_YES);
////    SetAttribute("SHOWRENAME", IUP_YES);

    }

    child_array1 ~= tree_fs;

    auto toggle1 = new Toggle("toggle_op_file_possible_suppress", __("Suppress rare operations like delete, de-/activate"));
    toggle1.SetAttributeVALUE(IUP_ON);
    toggle1.SetCallback(IUP_ACTION, cast(Icallback) &toggle_op_file_possible_suppress_cb);
    child_array2 ~= toggle1;
    auto toggle2 = new Toggle("toggle_auto_read", __("Perform 'Read operation' automatically, if applicable and doesn't require authorization (except SM related)"));
    toggle2.SetAttributeVALUE(IUP_ON);
    toggle2.SetCallback(IUP_ACTION, cast(Icallback) &toggle_auto_read_cb);
    child_array2 ~= toggle2;

    auto list = new List("list_op_file_possible");
    with (list) {
        SetInteger  (IUP_SIZE, 100);
        SetAttribute(IUP_DROPDOWN, IUP_YES);
        SetInteger  (IUP_VISIBLEITEMS, 7);
//  final void   SetAttributeId(const(char)* name, int id, const(char)* value) @nogc {         IupSetAttributeId(_ih, name, id, value); }
//        SetAttributeId("", 1, "Read");
        SetAttribute("1", "Read");
        SetAttribute("2", "Update");
        SetAttribute("3", "---");
        SetAttribute("4", "Deactivate/Invalidate");
        SetAttribute("5", "Activate/Rehabilitate");
        SetAttribute("6", "Terminate/Lock");
        SetAttribute("7", "Delete Self");
        SetAttribute("8", null);
//      SetAttribute(IUP_VALUE, "1");
        SetCallback(IUP_VALUECHANGED_CB, &list_op_file_possible_val_changed_cb);
    }
    child_array2 ~= list;
    child_array2 ~= new Label("Read-Result (hexadecimal; content ending with 4 zero bytes indicates: There were possibly more zero bytes, subject to 'zero byte truncation')");

    auto text1 = new Text("fs_text");
    with (text1) {
        SetAttribute(IUP_SIZE, "650");
        SetAttribute(IUP_MULTILINE, IUP_YES);
        SetAttribute(IUP_VISIBLELINES, "10");
        SetAttribute(IUP_WORDWRAP, IUP_YES);
    }
    child_array2 ~= text1;

    auto toggle3 = new Toggle("toggle_auto_decode_asn1", __("Perform 'Read operation result ASN.1-decoding' automatically for transparent files (for RSA: openssh format)"));
    toggle3.SetAttributeVALUE(IUP_ON);
    toggle3.SetCallback(IUP_ACTION, cast(Icallback) &toggle_auto_decode_asn1_cb);
    child_array2 ~= toggle3;

    auto text2 = new Text("fs_text_asn1");
    with (text2) {
        SetAttribute(IUP_SIZE, "650");
        SetAttribute(IUP_MULTILINE, IUP_YES);
        SetAttribute(IUP_VISIBLELINES, "30");
        SetAttribute(IUP_WORDWRAP, IUP_YES);

        SetAttribute(IUP_READONLY, IUP_YES);
    }
    child_array2 ~= text2;

    child_array1 ~= new Vbox(child_array2, FILL_TYPE.FILL_BETWEEN);

    auto hbox = new Hbox(child_array1, FILL_TYPE.FILL_FRONT_AND_BACK_AND_BETWEEN);
    hbox.SetAttribute(ICTL_TABTITLE, "file system (read only)");
    return hbox;
}

private Vbox create_ssh_tab() {
/*
remember to inform:
/etc/ssh/ssh_config or user's config file requires an entry like
PKCS11Provider /usr/lib/opensc-pkcs11.so   or
PKCS11Provider /usr/lib/x86_64-linux-gnu/opensc-pkcs11.so
so that ssh client is informed to look for keys via PKCS#11 in a card/token and which library to use for that (where to find it)

https://help.github.com/articles/testing-your-ssh-connection/
ssh -T git@github.com

If PKCS11Provider is not specified, the command will be
ssh -I /path/to/opensc-pkcs11.so -T git@github.com
*/
    auto vbox = new Vbox();
    vbox.SetAttribute(ICTL_TABTITLE, "ssh");
    return vbox;
}

private Vbox create_GenerateKeyPair_RSA_tab() {
    Control[]  child_array, child_array_toggles;

    auto text1 = new Text("gkpRSA_text");
    with (text1) {
        SetAttribute(IUP_SIZE, "800");
        SetAttribute(IUP_MULTILINE, IUP_YES);
        SetAttribute(IUP_VISIBLELINES, "8");
        SetAttribute(IUP_WORDWRAP, IUP_YES);
    }
    child_array ~= text1;

    auto toggle1 = new Toggle("toggle_RSA_PrKDF_PuKDF_change", __("PrKDF/PuKDF only: Change some administrative (PKCS#15) data, but no change concerning RSA key pair content (select by key pair id)"));
    child_array_toggles ~= toggle1;
//    auto toggle2 = new Toggle("toggle_RSA_key_pair_delete", __("RSA key pair: Delete key pair files (select by key pair id)"));
//    child_array_toggles ~= toggle2;
    auto toggle3 = new Toggle("toggle_RSA_key_pair_generate", __("RSA key pair: Regenerate RSA key pair content in existing files (select by key pair id)"));
    child_array_toggles ~= toggle3;
//    auto toggle4 = new Toggle("toggle_RSA_key_pair_create_and_generate", __("RSA key pair: Create new RSA key pair files and generate RSA key pair content"));
//    child_array_toggles ~= toggle4;

    foreach (i,toggle; child_array_toggles) {
        toggle.SetAttributeVALUE(i==0? IUP_ON : IUP_OFF);
        toggle.SetCallback(IUP_ACTION, cast(Icallback) &toggle_RSA_cb);
    }
    child_array  ~= new Radio("radio_RSA", new Vbox(child_array_toggles, FILL_TYPE.FILL_FRONT_AND_BACK_AND_BETWEEN));

    auto text2 = new Text();
    with (text2) {
        SetAttribute(IUP_SIZE, "500");
        SetAttribute(IUP_READONLY, IUP_YES);
        SetStringVALUE("Integer entry for private key usage/capability: 2(decrypt) +4(sign) +8(signRecover) +32(unwrap) +512(nonRepudiation)");
    }
    child_array ~= text2;

/*  Matrix("matrixRsaAttributes") is designed to work in "normal" mode !
IupMatrix
It has two modes of operation: normal and callback mode.
In normal mode, string values are stored in attributes for each cell.
In callback mode these attributes are ignored and the cells are filled with strings returned by the "VALUE_CB" callback.
So the existence of this callback defines the matrix operation mode.
*/
    auto matrix = new Matrix("matrixRsaAttributes");
    with (matrix) {
        SetInteger(IUP_NUMLIN,         r_AC_Create_Delete_RSADir);
        SetInteger(IUP_NUMLIN_VISIBLE, r_AC_Create_Delete_RSADir);
        SetInteger(IUP_NUMCOL,          2);
        SetInteger(IUP_NUMCOL_VISIBLE,  2);
        SetAttribute(IUP_RESIZEMATRIX, IUP_YES);
//      SetAttribute("LIMITEXPAND",  IUP_YES);
        SetAttribute(IUP_READONLY,     IUP_NO);
//      SetAttribute("FLATSCROLLBAR",     IUP_YES);
//      SetAttribute("EDITNEXT",     "COL");
        SetIntegerId(IUP_WIDTH,   0,    400);
        SetIntegerId(IUP_WIDTH,   1,    130);
        SetIntegerId(IUP_WIDTH,   2,    230);
        SetInteger(IUP_HEIGHTDEF, 6);

        SetAttributeId2("",  0,                         0,   __("RSA key pair and PrKDF, PuKDF attributes"));
        SetAttributeId2("",  0,                         1,   __("value"));
        SetAttributeId2("",  0,                         2,   __("Stored where? (private key file should be unreadable)"));
        SetAttributeId2("",  r_acos_internal,           0,   __("Acos key generation settings"));

        SetAttributeId2("",  r_sizeNewRSAModulusBits,   0,   __("Modulus bitLength"));
        SetAttributeId2("",  r_sizeNewRSAModulusBits,   2,   __("keypair files, PrKDF, PuKDF"));
        SetAttributeId2("",  r_storeAsCRTRSAprivate,    0,   __("    Private key stored acc. ChineseRemainderTheorem ?"));
        SetAttributeId2("",  r_storeAsCRTRSAprivate,    2,   __("CRT contents do or don't exist in private key file"));
        SetAttributeId2("",  r_usageRSAprivateKeyACOS,  0,   __("    Private key core capability (4)sign, (2)decrypt, (6)sign+decrypt (enter as int, shown as text)"));
        SetAttributeId2("",  r_usageRSAprivateKeyACOS,  2,   __("private key file"));
        SetAttributeId2("",  r_keyPairLabel,            0,   __("Key pair label"));
        SetAttributeId2("",  r_keyPairLabel,            2,   __("PrKDF, PuKDF"));
        SetAttributeId2("",  r_keyPairId,               0,   __("Key pair id (1 byte hex. 01..FF)"));
//      SetAttributeId2("",  r_keyPairId,               1,   "4"); // => PrKDF/PuKDF
        SetAttributeId2("",  r_keyPairId,               2,   __("PrKDF, PuKDF"));

        SetAttributeId2("",  r_fidRSADir,               0,   __("File id of enclosing directory (2 bytes hex.)"));
//      SetAttributeId2("",  r_fidRSADir,               1,   "16640"); // =>
        SetAttributeId2("",  r_fidRSADir,               2,   __("PrKDF, PuKDF"));
        SetAttributeId2("",  r_fidRSAprivate,           0,   __("File id of private key (2 bytes hex.)"));
//      SetAttributeId2("",  r_fidRSAprivate,           1,   "16881"); // => PrKDF
        SetAttributeId2("",  r_fidRSAprivate,           2,   __("PrKDF, public key file"));
        SetAttributeId2("",  r_fidRSApublic,            0,   __("File id of public key (2 bytes hex.)"));
//      SetAttributeId2("",  r_fidRSApublic,            1,   "16689"); // => PuKDF
        SetAttributeId2("",  r_fidRSApublic,            2,   __("PuKDF, private key file"));
        SetAttributeId2("",  r_sizeNewRSAprivateFile,   0,   __("Private key file size (bytes) available / required"));
//      SetAttributeId2("",  r_sizeNewRSAprivateFile,   1,   "? / 1585"); // <=
        SetAttributeId2("",  r_sizeNewRSAprivateFile,   2,   __("Header (FCI) of private key file"));
        SetAttributeId2("",  r_sizeNewRSApublicFile,    0,   __("Public key file size (bytes) available / required"));
//      SetAttributeId2("",  r_sizeNewRSApublicFile,    1,   "? / 533");
        SetAttributeId2("",  r_sizeNewRSApublicFile,    2,   __("Header (FCI) of public key file"));
        SetAttributeId2("",  r_change_calcPrKDF,        0,   __("PrKDF change calc.")); //  / unused available A/A
        SetAttributeId2("",  r_change_calcPrKDF,        1,   "?");
        SetAttributeId2("",  r_change_calcPuKDF,        0,   __("PuKDF change calc.")); //  / does it fit into file size? A/A
        SetAttributeId2("",  r_change_calcPuKDF,        1,   "?");
        SetAttributeId2("",  r_authIdRSAprivateFile,    0,   __("authId (that protects private key; 1 byte hex. 01..FF)"));
        SetAttributeId2("",  r_authIdRSAprivateFile,    2,   __("PrKDF"));
        SetAttributeId2("",  r_valuePublicExponent,     0,   __("Public exponent e (a prime, default 0x10001; max 16 bytes hex., leading zero bytes trimmed)  0x"));
        SetAttributeId2("",  r_valuePublicExponent,     2,   __("public key file"));
        SetAttributeId2("",  r_statusInput,             0,   __("Status of input (whether all required info is okay for the operation"));
        SetAttributeId2("",  r_statusInput,             1,  "No");
        SetRGBId2(IUP_BGCOLOR, r_statusInput, 1,  255, 0, 0);
        SetAttributeId2("",  r_usageRSAprivateKeyPrKDF, 0,   __("Private key usage PrKDF (enter as int, 2.. max 558, shown as text)"));
        SetAttributeId2("",  r_usageRSAprivateKeyPrKDF, 2,   __("PrKDF"));
        SetAttributeId2("",  r_usageRSApublicKeyPuKDF,  0,   __("Public key usage PuKDF (enter as int, 1.. max 209, shown as text)"));
//      SetAttributeId2("",  r_usageRSApublicKeyPuKDF,  1,   "");
        SetAttributeId2("",  r_usageRSApublicKeyPuKDF,  2,   __("PuKDF"));
        SetAttributeId2("",  r_keyPairModifiable,       0,   __("Key pair is modifiable?"));
        SetAttributeId2("",  r_keyPairModifiable,       2,   __("PrKDF, PuKDF"));

        SetAttributeId2("",  r_AC_Update_PrKDF_PuKDF,   0,   __("Access Control condition for Update: PrKDF / PuKDF (SCB hex shown; 0x00 means unrestricted)"));
        SetAttributeId2("",  r_AC_Update_Delete_RSAprivateFile,0,   __("Access Control condition for Update / Delete: Private key file"));
        SetAttributeId2("",  r_AC_Update_Delete_RSApublicFile, 0,   __("Access Control condition for Update / Delete: Public key file"));
        SetAttributeId2("",  r_AC_Create_Delete_RSADir,        0,   __("Access Control condition for Create / Delete: Enclosing DF"));
        SetAttribute(IUP_TOGGLECENTERED, IUP_YES);

        SetCallback(IUP_DROPCHECK_CB,  cast(Icallback)&matrixRsaAttributes_dropcheck_cb);
        SetCallback(IUP_DROP_CB,       cast(Icallback)&matrixRsaAttributes_drop_cb);
        SetCallback(IUP_DROPSELECT_CB, cast(Icallback)&matrixRsaAttributes_dropselect_cb);
        SetCallback(IUP_EDITION_CB,    cast(Icallback)&matrixRsaAttributes_edition_cb);
        SetCallback(IUP_TOGGLEVALUE_CB,cast(Icallback)&matrixRsaAttributes_togglevalue_cb);
//        SetCallback(IUP_CLICK_CB,      cast(Icallback)&matrixRsaAttributes_click_cb);
    }
    child_array ~= matrix;

    auto btn_RSA = new Button("btn_RSA",  __("PrKDF/PuKDF only: Change some administrative (PKCS#15) data")); // this(string CN, const(char)* title)
    btn_RSA.SetCallback(IUP_ACTION, &btn_RSA_cb);
    btn_RSA.SetAttribute(IUP_TIP, __("The action performed depends on the radio button setting"));
    Control[] child_array3;
    child_array3 ~= btn_RSA;
    child_array ~= new Hbox(child_array3, FILL_TYPE.FILL_FRONT_AND_BACK);

    auto vbox = new Vbox(child_array/*, FILL_TYPE.FILL_FRONT_AND_BACK_AND_BETWEEN*/);
    vbox.SetAttribute(ICTL_TABTITLE, "GenerateKeyPair (RSA)");
    return vbox;
}

private Vbox create_sanityCheck_tab() {
    Control[]  child_array;

    auto text1 = new Text("sanity_overview_text");
    with (text1) {
        SetInteger(IUP_SIZE, 900);
        SetAttribute(IUP_MULTILINE, IUP_YES);
        SetInteger(IUP_VISIBLELINES, 8);
        SetAttribute(IUP_WORDWRAP,  IUP_YES);
    }
    child_array ~= text1;

    auto matrix = new Matrix("matrixsanity");
    with (matrix) {
        SetInteger(IUP_NUMLIN,         3);
        SetInteger(IUP_NUMLIN_VISIBLE, 3);
        SetInteger(IUP_NUMCOL,         2);
        SetInteger(IUP_NUMCOL_VISIBLE, 2);
        SetAttribute(IUP_RESIZEMATRIX, IUP_YES);
//      SetAttribute("LIMITEXPAND",  IUP_YES);
        SetAttribute(IUP_READONLY,     IUP_NO);
//      SetAttribute("FLATSCROLLBAR",     IUP_YES);
//      SetAttribute("EDITNEXT",     "COL");
        SetIntegerId(IUP_WIDTH,   0,    250);
        SetIntegerId(IUP_WIDTH,   1,    130);
        SetIntegerId(IUP_WIDTH,   2,    400);
        SetInteger(IUP_HEIGHTDEF, 6);

        SetAttributeId2("",  0,   0,   __("Attributes"));
        SetAttributeId2("",  0,   1,   __("value"));
        SetAttributeId2("",  0,   2,   __("Meaning"));
        SetAttributeId2("",  1,   0,   __("Card type from match ATR"));
        SetAttributeId2("",  1,   2,   __("16003: ACOS5-64 V2.00 (Card/CryptoMate64);  16004: ACOS5-64 V3.00 (Card/CryptoMate Nano)"));

        SetAttributeId2("",  2,   0,   __("Card OS version major/minor from command 'Get Card Info'"));
        SetAttributeId2("",  2,   2,   __("Reflects both: Card type and Operation Mode Byte setting"));
        SetAttributeId2("",  3,   0,   __("Operation Mode Byte setting from command 'Get Card Info'"));
        SetAttributeId2("",  3,   2,   __("Non-retrievable for ACOS5-64 V2.00"));
        SetAttribute(IUP_TOGGLECENTERED, IUP_YES);

//        SetCallback(IUP_DROPCHECK_CB,  cast(Icallback)&matrixRsaAttributes_dropcheck_cb);
//        SetCallback(IUP_DROP_CB,       cast(Icallback)&matrixRsaAttributes_drop_cb);
//        SetCallback(IUP_DROPSELECT_CB, cast(Icallback)&matrixRsaAttributes_dropselect_cb);
//        SetCallback(IUP_EDITION_CB,    cast(Icallback)&matrixRsaAttributes_edition_cb);
//        SetCallback(IUP_TOGGLEVALUE_CB,cast(Icallback)&matrixRsaAttributes_togglevalue_cb);
//        SetCallback(IUP_CLICK_CB,      cast(Icallback)&matrixRsaAttributes_click_cb);
    }
    child_array ~= matrix;

    auto text2 = new Text("sanity_text");
    with (text2) {
        SetInteger(IUP_SIZE, 900);
        SetAttribute(IUP_MULTILINE, IUP_YES);
        SetInteger(IUP_VISIBLELINES, 30);
        SetAttribute(IUP_WORDWRAP, IUP_YES);
    }
    child_array ~= text2;

    auto btn_sanity = new Button("btn_sanity",  __("Perform sanity check"));
    btn_sanity.SetCallback(IUP_ACTION, &btn_sanity_cb);
//    btn_sanity.SetAttribute(IUP_TIP, __("The action performed depends on the radio button setting"));
    Control[] child_array3;
    child_array3 ~= btn_sanity;
    child_array ~= new Hbox(child_array3, FILL_TYPE.FILL_FRONT_AND_BACK);

    auto vbox = new Vbox(child_array, FILL_TYPE.FILL_BETWEEN);
    vbox.SetAttribute(ICTL_TABTITLE, "sanityCheck");
    return vbox;
}

Dialog create_dialog_dlg0() {
    /* Example of i18n usage */
    auto btn_exit    = new Button(  __("Exit")); // __("Beenden")
////  btn_exit.SetCallback(IUP_ACTION, &dlg0_exit);
    btn_exit.SetAttribute(IUP_TIP, __("more to come"));

    auto hbox = new Hbox([ btn_exit ], FILL_TYPE.FILL_FRONT_AND_BACK_AND_BETWEEN);

    Control[] child_array = [create_cryptoki_slot_tokeninfo_tab/*, create_opensc_conf_tab*/, create_filesystem_tab, create_GenerateKeyPair_RSA_tab /*, create_ssh_tab*/
        /*,create_sanityCheck_tab*/];
    auto tabs = new Tabs("tabCtrl", child_array);
//  tabs.SetAttribute(ICTL_TABTYPE, ICTL_TOP); // Default is "TOP"

    auto lbl_statusbar = new Label("statusbar", "statusbar");
    lbl_statusbar.SetAttribute(IUP_EXPAND, IUP_HORIZONTAL);
    lbl_statusbar.SetAttribute(IUP_PADDING, "10x5");

    auto vbox = new Vbox(/*new Fill, */ hbox /*, new Fill*/, tabs, lbl_statusbar);
    auto dialog = new Dialog("dlg0", true, vbox);
    dialog.SetAttribute(IUP_TITLE, __("tool for driver acos5_64"));
    dialog.SetAttribute(IUP_MARGIN, "2x2");
    return dialog;
}

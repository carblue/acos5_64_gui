/*
 * Written in the D programming language, part of package acos5_64_gui.
 * util_opensc.d:
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

//    import core.stdc.stdlib : exit, malloc, EXIT_FAILURE;
//    import std.stdio;
//    import std.algorithm.searching;
//    import std.algorithm.comparison;
/+ + /
//        "sand": "~>0.0.5"
//    import sane;
    import sand;

    // Initialise sane interface
    auto sane = new Sane();

    // Find all devices
    auto devices = sane.devices();

    // List all options for a device
    if(devices.length) {
        auto options = devices[0].options;
        foreach (option; options) {
            writeln(option);
        }
    }
/ + +/
/*
  This software and all software it makes use of, is subject to a lot of standards, restrictions/limitations/conventions/rules, some of which are explicit
  in standard, reference manual documents, others are less obvious (implicit) backed into the software like libopensc, the driver or this gui-tool.

  With files, several operations may be performed, most of which are common to all files, some only possible with specific file types.
  Further, file access conditions may require some legitimation(s) or may inhibit operation(s) at all.

  Prohibitions are coded within a file and possibly in it's parent directory
  Limitations  are coded within a file, it's parent directory's Security Environment File and possibly in it's parent directory
  When a file/directory is marked, the DropDown is updated with possible operation(s) (omitting Prohibitions) and the header info (File Control Information/Meta data) are shown
  When a possible operation is selected from the DropDown, then the first thing to show are the conditions that must be satisfied, if any.
  If the operation is e.g. Read and all  conditions are fulfilled, the file content is shown in hexadecimal format, possibly also (if it's ASN.1 content)  ASN.1-decoded
*/
module util_opensc;

import core.sys.posix.dlfcn;

import core.runtime : Runtime;
import core.stdc.stdlib : EXIT_SUCCESS, EXIT_FAILURE, exit, getenv, strtol; //, div_t, div, malloc, free;
import core.stdc.config : c_long, c_ulong;
import core.stdc.string;
import std.stdio;
import std.string; // fromStringz, toStringz;
import std.conv : to;
import std.format;
import std.exception : assumeWontThrow, assumeUnique;
import std.algorithm.comparison : min, equal, clamp, /*max, mismatch,*/ among;
import std.algorithm.searching : count, minElement, minIndex, countUntil, any, endsWith, canFind;
import std.algorithm.iteration : /*filter,*/ uniq;
import std.algorithm.mutation : remove;
import std.traits : EnumMembers;
import std.typecons : Tuple;
import std.digest : toHexString;
import std.range : iota, slide, chunks/*, enumerate*/;
import std.base64 : Base64;

import libopensc.opensc;// "dependencies" : "opensc": "==0.15.14",   : sc_card,SC_ALGORITHM_DES, SC_ALGORITHM_3DES, SC_ALGORITHM_AES; // to much to make sense listing // sc_format_path, SC_ALGORITHM_RSA, sc_print_path, sc_file_get_acl_entry
import libopensc.types;  // to much to make sense listing // sc_path, sc_atr, sc_file, sc_serial_number, SC_MAX_PATH_SIZE, SC_PATH_TYPE_PATH, sc_apdu, SC_AC_OP_GENERATE;
import libopensc.errors; // to much to make sense listing ?
import libopensc.log;
import libopensc.iso7816;
import libopensc.pkcs15 : SC_PKCS15_DF, sc_pkcs15_prkey, sc_pkcs15_bignum;

import iup.iup_plusD;

import libtasn1;// : asn1_node, ASN1_MAX_ERROR_DESCRIPTION_SIZE, asn1_create_element, asn1_delete_structure, asn1_der_decoding,
//  ASN1_SUCCESS, ASN1_ELEMENT_NOT_FOUND, asn1_strerror, asn1_read_value, asn1_dup_node;

import tree_k_ary;
import acos5_64_shared;
import util_general;


struct PKCS15_ObjectTyp {
    uint             posStart; // included, offset starting at begin of file, where bytes for ... do start
    uint             posEnd;   // excluded, offset starting at begin of file, where bytes for ... do end
    ubyte[]          der;
    ubyte[]          der_new;
    asn1_node        structure;     // to be used with der
    asn1_node        structure_new; // to be used with der_new
}

enum PKCS15_FILE_TYPE : ubyte {
    PKCS15_PRKDF          = SC_PKCS15_DF.SC_PKCS15_PRKDF,         // = 0,
    PKCS15_PUKDF          = SC_PKCS15_DF.SC_PKCS15_PUKDF,         // = 1,
    PKCS15_PUKDF_TRUSTED  = SC_PKCS15_DF.SC_PKCS15_PUKDF_TRUSTED, // = 2,   DOESN'T NEED DETECTION !
    PKCS15_SKDF           = SC_PKCS15_DF.SC_PKCS15_SKDF,          // = 3,
    PKCS15_CDF            = SC_PKCS15_DF.SC_PKCS15_CDF,           // = 4,
    PKCS15_CDF_TRUSTED    = SC_PKCS15_DF.SC_PKCS15_CDF_TRUSTED,   // = 5,   DOESN'T NEED DETECTION !
    PKCS15_CDF_USEFUL     = SC_PKCS15_DF.SC_PKCS15_CDF_USEFUL,    // = 6,   DOESN'T NEED DETECTION !
    PKCS15_DODF           = SC_PKCS15_DF.SC_PKCS15_DODF,          // = 7,
    PKCS15_AODF           = SC_PKCS15_DF.SC_PKCS15_AODF,          // = 8,

    PKCS15_RSAPublicKey   = 9,  // e.g. file 0x4131  (arbitrary, when read by read_public_key, asn1-der-encoded public RSA key file) RSA_PUB

    PKCS15_DIR            = 10, // file 0x2F00  (fix acc. to ISO/IEC 7816-4)
    PKCS15_ODF            = 11, // file 0x5031  (fix acc. to ISO/IEC 7816-4 or indicated in file 0x2F00)
    PKCS15_TOKENINFO      = 12, // file 0x5032  (fix acc. to ISO/IEC 7816-4 or indicated in file 0x2F00)
    PKCS15_UNUSED         = 13, // file 0x5033  (fix acc. to ISO/IEC 7816-4 or indicated in file 0x2F00)   DOESN'T NEED DETECTION  ???
    PKCS15_APPDF          = 14, // file 0x4100  (arbitrary)                    DOESN'T NEED DETECTION !
    PKCS15_Cert           = 15,
    PKCS15_RSAPrivateKey  = 16,
    PKCS15_SecretKey      = 17,
    PKCS15_Pin            = 18,
    PKCS15_Data           = 19,
    PKCS15_NONE           = 0xFF, // should not happen to extract a path for this
}
//mixin FreeEnumMembers!PKCS15_FILE_TYPE;

string[5][] pkcs15_names = [
    [ "EF(PrKDF)",        "PKCS15.PrivateKeyType",     "privateKeys.path.path",         "PKCS15.PrivateKeyType", "privateRSAKey"],    // 0
    [ "EF(PuKDF)",        "PKCS15.PublicKeyType",      "publicKeys.path.path",          "PKCS15.PublicKeyType",  "publicRSAKey"],
    [ "EF(PuKD_TRUSTED)", "PKCS15.PublicKeyType",      "trustedPublicKeys.path.path",   "PKCS15.PublicKeyType", ""],
    [ "EF(SKDF)",         "PKCS15.SecretKeyType",      "secretKeys.path.path",          "PKCS15.SecretKeyTypeChoice", "secretKey"],
    [ "EF(CDF)",          "PKCS15.CertificateType",    "certificates.path.path",        "PKCS15.CertificateType", "x509Certificate"],
    [ "EF(CDF_TRUSTED)",  "PKCS15.CertificateType",    "trustedCertificates.path.path", "PKCS15.CertificateType", "x509Certificate"],
    [ "EF(CDF_USEFUL)",   "PKCS15.CertificateType",    "usefulCertificates.path.path",  "PKCS15.CertificateType", "x509Certificate"],
    [ "EF(DODF)",         "PKCS15.DataType",           "dataObjects.path.path",         "PKCS15.DataType", "opaqueDO"],
    [ "EF(AODF)",         "PKCS15.AuthenticationType", "authObjects.path.path",         "PKCS15.AuthenticationTypeChoice", "authObj"],

    [ "EF(RSA_PUB)",      "PKCS15.RSAPublicKey", "publicRSAKey.publicRSAKeyAttributes.value.indirect.path.path",       "PKCS15.RSAPublicKeyChoice", "raw"],    // 9

    [ "EF(DIR)",          "PKCS15.DIRRecord",          "path",                          "PKCS15.DIRRecordChoice", "dirRecord"],
    [ "EF(ODF)",          "PKCS15.PKCS15Objects",      "",                              "PKCS15.PKCS15ObjectsChoice", "pkcs15Objects"],
    [ "EF(TokenInfo)",    "PKCS15.TokenInfo",          "",                              "PKCS15.TokenInfoChoice", "tokenInfo"],
    [ "EF(UnusedSpace)",  "",                          "",                              "", ""],
    [ "DF.CIA",           "",                          "",                              "", ""],         // 14
    [ "EF(Cert)",         "PKCS15.Certificate",  "x509Certificate.x509CertificateAttributes.value.indirect.path.path", "PKCS15.CertificateChoice", "certificate"],       // 15
    [ "EF(RSA_PRIV)",     "",                    "privateRSAKey.privateRSAKeyAttributes.value.indirect.path.path",     "", ""],  // 16
    [ "EF(SecretKey)",    "",                          "",                              "", ""],  // 17
    [ "EF(Pin)",          "",                          "",                              "", ""],        // 18
    [ "EF(Data)",         "",                    "opaqueDO.opaque.value.indirect.path.path",  "", ""],       // 19
];

struct PKCS15Path_FileType {
    ubyte[]           path;
    PKCS15_FILE_TYPE  pkcs15FileType;

    import mixin_templates_opensc;

version(ENABLE_TOSTRING)
    void toString(scope void delegate(const(char)[]) sink, FormatSpec!char fmt) const
    {
        mixin(frame_noPointer_OneArrayFormatx_noUnion!("path", "path.length", "path.length"));
    }
} // struct PKCS15Path_FileType

/*
  The layout of the tree_k_ary.Tree!ub32 data/payload:
  ubyte[32]: It's first 8 bytes basically are the return value from acos command: Get Card Info/File Information,
//             The 8 bytes file information are: {FDB, DCB (replaced by length path), FILE ID, FILE ID, SIZE or MRL, SIZE or NOR, SFI (replaced by enum PKCS15_FILE_TYPE), LCSI};
             it's next 16 bytes are for storing a file path.
             it's last  8 bytes are SAC (as provided by acos5_64_short_select).
             Some bytes of the file information ubyte[8] are replaced though with other content:
        [0]: FDB File Descriptor Byte, see also Reference Manual for values
        [1]: (originally DCB always zero), replaced by the Length of path ubyte[16] actually used (from the beginning, i.e. path[0..Length])
        [2]: FILE ID (MSB)
        [3]: FILE ID (LSB)
        [4]: depending on FDB: FILE ID (MSB) or MRL (Max. Record Length)
        [5]: depending on FDB: FILE ID (LSB) or NOR (Number of Records)
        [6]: (originally SFI), replaced by default 0xFF or if applicable, the meaning expressed as  enum PKCS15_FILE_TYPE, that this file has for PKCS#15, i.e.
             tree traversal for all nodes with data[6]!=0xFF visits all files relevant for the PKCS#15 file structure or mentioned in PKCS#15 files,
             e.g. only those public RSA key files, that are listed in EF.PuKD will get the image symbol IUP_IMGBLANK; there may be other RSA files not known to PKCS#15,
             that get decorated as any other non-PKCS#15 file with the default: "IMGLEAF" (a bullet).
        [7]: LCSI Life Cycle Status Integer
*/

alias  TreeTypeFS = tree_k_ary.Tree!ub32; // 8 bytes + length of pathlen_max considered (, here SC_MAX_PATH_SIZE = 16) + 8 bytes SAC (file access conditions)
alias  tnTypePtr  = TreeTypeFS.nodeType*;
alias  sitTypeFS  = TreeTypeFS.sibling_iterator; // sibling iterator type
alias   itTypeFS  = TreeTypeFS.pre_order_iterator; // iterator type

bool        doCheckPKCS15 = true;
TreeTypeFS  fs;
tnTypePtr   appdf;
tnTypePtr   prkdf;
tnTypePtr   pukdf;
itTypeFS    iter_begin;

asn1_node  PKCS15;
string errorDescription;

PKCS15_ObjectTyp[]            PRKDF; /*0*/
PKCS15_ObjectTyp[]            PUKDF; /*1*/
PKCS15_ObjectTyp[]            PUKDF_TRUSTED; /*2*/
PKCS15_ObjectTyp[]            SKDF; /*3*/
PKCS15_ObjectTyp[]            CDF; /*4*/
PKCS15_ObjectTyp[]            CDF_TRUSTED; /*5*/
PKCS15_ObjectTyp[]            CDF_USEFUL; /*6*/
PKCS15_ObjectTyp[]            DODF; /*7*/
PKCS15_ObjectTyp[]            AODF; /*8*/

__gshared sc_card*            card;
__gshared void*               lh; // library handle
ft_cm_7_3_1_14_get_card_info  cm_7_3_1_14_get_card_info;
ft_acos5_64_short_select      acos5_64_short_select;
ft_uploadHexfile              uploadHexfile;

//ft_construct_sc_security_env  construct_sc_security_env;
//ft_cry_mse_7_4_2_1_22_set     cry_mse_7_4_2_1_22_set;
ft_cry_____7_4_4___46_generate_keypair_RSA  cry_____7_4_4___46_generate_keypair_RSA;


    /* add space after name:, type: and value:
       pretty-print BIT STRING
    */
    string someScanner(int mode, const(char)[] line)
    {
        import core.stdc.stdlib : strtoull;
        import core.bitop : bitswap;
        import std.string : indexOf;
        import std.math : pow;

        string res;
        try {
            ptrdiff_t pos = indexOf(line, "name:");
            if (pos == -1)
                return  line.idup;
            res = assumeUnique(line[0..pos+5]) ~ " " ~ assumeUnique(line[pos+5..$]);
            if (mode>ASN1_PRINT_NAME) {
                pos = indexOf(res, "type:");
                if (pos != -1)
                  res = res[0..pos+5] ~ " " ~ res[pos+5..$];
            }
            if (mode>ASN1_PRINT_NAME_TYPE) {
                pos = indexOf(res, "value");
                if (pos != -1) {
                    import std.regex;
                    auto valueRegcolon     = regex(r"  value(?:\(\d+\)){0,1}:");
                    auto valueRegBITSTRING = regex(r".*value(?:\((\d+)\)){1}: ([0-9A-Fa-f]{2,16}){1}.*");
                    res = replaceFirst(res, valueRegcolon, "$& ");
                    auto m = matchFirst(res, valueRegBITSTRING);
                    if (!m.empty && to!int(m[1])<=64 && m[2].length<=16) {
                        ulong tmp = bitswap( strtoull(m[2].toStringz,null,16) << 8*(8-m[2].length/2));
                        res ~= "  ->  ";
                        foreach (i; 0..to!int(m[1]))
                            res ~= (tmp & pow(2,i))? "1" : "0";
                    }
                }
            }
            return  res;
        }
        catch (Exception e) { /* todo: handle exception */ }
        return  line.idup;
    }

Tuple!(ushort, ubyte, ubyte) decompose(EFDB fdb, /*ub2*/uba size_or_MRL_NOR) nothrow {
    assert(size_or_MRL_NOR.length==2);
    with (EFDB)
    final switch (fdb) {
        case Purse_EF:            return Tuple!(ushort, ubyte, ubyte)(0,0,0) ;// TODO
        case MF, DF:              return Tuple!(ushort, ubyte, ubyte)(0,0,0);
        case RSA_Key_EF,
             Transparent_EF:      return Tuple!(ushort, ubyte, ubyte)(ub22integral(size_or_MRL_NOR),0,0);
        case Linear_Fixed_EF,
             Linear_Variable_EF,
             Cyclic_EF,
             CHV_EF,
             Sym_Key_EF,
             SE_EF:               return Tuple!(ushort, ubyte, ubyte)(0,size_or_MRL_NOR[0],size_or_MRL_NOR[1]);
    }
}

Tuple!(string, string, string) decompose_str(EFDB fdb, ub2 size_or_MRL_NOR) nothrow {
    with (EFDB)
    final switch (fdb) {
        case MF, DF:              return Tuple!(string, string, string)("0","0","0");
        case RSA_Key_EF,
             Transparent_EF:      return Tuple!(string, string, string)(ub22integral(size_or_MRL_NOR).to!string,"0","0");
        case Linear_Fixed_EF,
             Linear_Variable_EF,
             Cyclic_EF,
             CHV_EF,
             Sym_Key_EF,
             SE_EF,
             Purse_EF:            return Tuple!(string, string, string)((size_or_MRL_NOR[0]*size_or_MRL_NOR[1]).to!string,
                                      size_or_MRL_NOR[0].to!string, size_or_MRL_NOR[1].to!string);
    }
}


// The 8 bytes are: {FDB, DCB (replaced by length path), FILE ID, FILE ID, SIZE or MRL, SIZE or NOR, SFI, LCSI};
string file_type(int depth, EFDB fdb, ushort fid, ub2 size_or_MRL_NOR) { // acos5_64.d: enum EFDB : ubyte
//    string msg = fid==0x2F00? "    DIR" : fid==0x5031? "    ODF" : fid==0x5032? "    TokenInfo" : fid==0x5033? "    UnusedSpace" : "";
    Tuple!(string, string, string) t = decompose_str(fdb, size_or_MRL_NOR);
    with (EFDB)
    final switch (fdb) {
        case DF:                  return "DF";
        case MF:                  return "MF";
        case Transparent_EF:      return "wEF transparent, size "~t[0]~" B";// ~ msg;
        case Linear_Fixed_EF:     return "wEF linear-fix, size "~t[0]~" ("~t[2]~"x"~t[1]~") B";
        case Linear_Variable_EF:  return "wEF linear-var, size max. "~t[0]~" ("~t[2]~"x"~t[1]~" max.) B";
        case Cyclic_EF:           return "wEF cyclic, size "~t[0]~" ("~t[2]~"x"~t[1]~") B";

        case RSA_Key_EF:          return "iEF transparent, size "~t[0]~" B";
        case CHV_EF:              return "iEF linear-fix, size "~t[0]~" ("~t[2]~"x"~t[1]~") B    Pin ("~ (depth==1? "global" : "local") ~ ")";
        case Sym_Key_EF:          return "iEF linear-var, size max. "~t[0]~" ("~t[2]~"x"~t[1]~" max.) B    SymKeys ("~ (depth==1? "global" : "local") ~ ")";
        case Purse_EF:            return "iEF cyclic ??, size "~t[0]~" ("~t[2]~"x"~t[1]~") B    Purse";
        case SE_EF:               return "iEF linear-var, size max. "~t[0]~" ("~t[2]~"x"~t[1]~" max.) B    SecEnv of directory";
    }
}

/* All singing all dancing card connect routine */ // copied from acos5_64.d
int util_connect_card(sc_context* ctx, scope sc_card** cardp, const(char)* reader_id, int do_wait, int do_lock, int verbose) nothrow @trusted
{ // copy of tools/util.c:util_connect_card_ex

int is_string_valid_atr(const(char)* atr_str)
{ // copy of tools/is_string_valid_atr
    ubyte[SC_MAX_ATR_SIZE]  atr;
    size_t atr_len = atr.sizeof;

    if (sc_hex_to_bin(atr_str, atr.ptr, &atr_len))
        return 0;
    if (atr_len < 2)
        return 0;
    if (atr[0] != 0x3B && atr[0] != 0x3F)
        return 0;
    return 1;
}

    sc_reader*  reader, found;
    sc_card*    card;
    int r;

    if (do_wait) {
        uint event;

        if (sc_ctx_get_reader_count(ctx) == 0) {
            /*fprintf(stderr.getFP(),*/ assumeWontThrow(writeln("Waiting for a reader to be attached..."));
            r = sc_wait_for_event(ctx, SC_EVENT_READER_ATTACHED, &found, &event, -1, null);
            if (r < 0) {
                fprintf(assumeWontThrow(stderr.getFP()), "Error while waiting for a reader: %s\n", sc_strerror(r));
                return 3;
            }
            r = sc_ctx_detect_readers(ctx);
            if (r < 0) {
                fprintf(assumeWontThrow(stderr.getFP()), "Error while refreshing readers: %s\n", sc_strerror(r));
                return 3;
            }
        }
        fprintf(assumeWontThrow(stderr.getFP()), "Waiting for a card to be inserted...\n");
        r = sc_wait_for_event(ctx, SC_EVENT_CARD_INSERTED, &found, &event, -1, null);
        if (r < 0) {
            fprintf(assumeWontThrow(stderr.getFP()), "Error while waiting for a card: %s\n", sc_strerror(r));
            return 3;
        }
        reader = found;
    }
    else if (sc_ctx_get_reader_count(ctx) == 0) {
        fprintf(assumeWontThrow(stderr.getFP()), "No smart card readers found.\n");
        return 1;
    }
    else   {
        if (!reader_id) {
            uint i;
            /* Automatically try to skip to a reader with a card if reader not specified */
            for (i = 0; i < sc_ctx_get_reader_count(ctx); i++) {
                reader = sc_ctx_get_reader(ctx, i);
                if (sc_detect_card_presence(reader) & SC_READER_CARD_PRESENT) {
                    if (verbose)
                        fprintf(assumeWontThrow(stderr.getFP()), "Using reader with a card: %s\n", reader.name);
                    goto autofound;
                }
            }
            /* If no reader had a card, default to the first reader */
            reader = sc_ctx_get_reader(ctx, 0);
        }
        else {
            /* If the reader identifier looks like an ATR, try to find the reader with that card */
            if (is_string_valid_atr(reader_id))   {
                ubyte[SC_MAX_ATR_SIZE * 3]  atr_buf;
                size_t atr_buf_len = atr_buf.sizeof;
                uint i;

                sc_hex_to_bin(reader_id, atr_buf.ptr, &atr_buf_len);
                /* Loop readers, looking for a card with ATR */
                for (i = 0; i < sc_ctx_get_reader_count(ctx); i++) {
                    sc_reader* rdr = sc_ctx_get_reader(ctx, i);

                    if (!(sc_detect_card_presence(rdr) & SC_READER_CARD_PRESENT))
                        continue;
                    else if (rdr.atr.len != atr_buf_len)
                        continue;
                    else if (memcmp(rdr.atr.value.ptr, atr_buf.ptr, rdr.atr.len))
                        continue;

                    fprintf(assumeWontThrow(stdout.getFP()), "Matched ATR in reader: %s\n", rdr.name);
                    reader = rdr;
                    goto autofound;
                }
            }
            else   {
                import core.stdc.errno;

                const(char)*   endptr  = null;
                const(char)**  endptrptr = &endptr;
                uint num;

                errno = 0;
                num = cast(uint)strtol(reader_id, endptrptr, 0);
                if (!errno && endptr && *endptr == '\0')
                    reader = sc_ctx_get_reader(ctx, num);
                else
                    reader = sc_ctx_get_reader_by_name(ctx, reader_id);
            }
        }
autofound:
        if (!reader) {
            fprintf(assumeWontThrow(stderr.getFP()), "Reader \"%s\" not found (%i reader(s) detected)\n",
                    reader_id, sc_ctx_get_reader_count(ctx));
            return 1;
        }

        if (sc_detect_card_presence(reader) <= 0) {
            fprintf(assumeWontThrow(stderr.getFP()), "Card not present.\n");
            return 3;
        }
    }

    if (verbose)
        printf("Connecting to card in reader %s...\n", reader.name);
    r = sc_connect_card(reader, &card);
    if (r < 0) {
        fprintf(assumeWontThrow(stderr.getFP()), "Failed to connect to card: %s\n", sc_strerror(r));
        return 1;
    }

    if (verbose)
        printf("Using card driver %s.\n", card.driver.name);

    if (do_lock) {
        r = sc_lock(card);
        if (r < 0) {
            fprintf(assumeWontThrow(stderr.getFP()), "Failed to lock card: %s\n", sc_strerror(r));
            sc_disconnect_card(card);
            return 1;
        }
    }

    *cardp = card;
    lh = assumeWontThrow(Runtime.loadLibrary("libacos5_64.so")); // this works without path (at least on Linux), as it is loaded already; nowadays libacos5_64.so is stored within standard so. library search path
////    assumeWontThrow(writeln("Library libacos5_64.so handle: ", lh));
    assert(lh);

    // some exported functions to call directly into libacos5_64.so
    cm_7_3_1_14_get_card_info = cast(ft_cm_7_3_1_14_get_card_info) dlsym(lh, "cm_7_3_1_14_get_card_info");
    char* error = dlerror();
    if (error)
    {
        printf("dlsym error cm_7_3_1_14_get_card_info: %s\n", error);
        exit(1);
    }
////    printf("cm_7_3_1_14_get_card_info() function is found\n");

    acos5_64_short_select = cast(ft_acos5_64_short_select) dlsym(lh, "acos5_64_short_select");
    error = dlerror();
    if (error)
    {
        printf("dlsym error acos5_64_short_select: %s\n", error);
        exit(1);
    }
////    printf("acos5_64_short_select() function is found\n");

    uploadHexfile = cast(ft_uploadHexfile) dlsym(lh, "uploadHexfile");
    error = dlerror();
    if (error)
    {
        printf("dlsym error uploadHexfile: %s\n", error);
        exit(1);
    }
////    printf("uploadHexfile() function is found\n");
/+
    construct_sc_security_env = cast(ft_construct_sc_security_env) dlsym(lh, "construct_sc_security_env");
    error = dlerror();
    if (error)
    {
        printf("dlsym error construct_sc_security_env: %s\n", error);
        exit(1);
    }
////    printf("construct_sc_security_env() function is found\n");

    cry_mse_7_4_2_1_22_set = cast(ft_cry_mse_7_4_2_1_22_set) dlsym(lh, "cry_mse_7_4_2_1_22_set");
    error = dlerror();
    if (error)
    {
        printf("dlsym error cry_mse_7_4_2_1_22_set: %s\n", error);
        exit(1);
    }
////    printf("cry_mse_7_4_2_1_22_set() function is found\n");
+/
    cry_____7_4_4___46_generate_keypair_RSA = cast(ft_cry_____7_4_4___46_generate_keypair_RSA) dlsym(lh, "cry_____7_4_4___46_generate_keypair_RSA");
    error = dlerror();
    if (error)
    {
        printf("dlsym error cry_____7_4_4___46_generate_keypair_RSA: %s\n", error);
        exit(1);
    }
////    printf("cry_____7_4_4___46_generate_keypair_RSA() function is found\n");

    return 0;
} // util_connect_card

template connect_card(string commands, string returning="IUP_CONTINUE", string level="0", string returning_no_card_statement="") {
	const char[] connect_card =`
	{
        import std.string : toStringz;
        /* connect to card */
        string debug_file = "/tmp/opensc-debug.log";

        int rc; // used for any return code except Cryptoki return codes, see next decl
        sc_context*         ctx;
        sc_context_param_t  ctx_param = { 0, "acos5_64_gui " };

        if ((rc= sc_context_create(&ctx, &ctx_param)) != SC_SUCCESS)
            return `~returning~`;
//        assert(ctx);
//        assumeWontThrow(writeln(*ctx));
        if (ctx is null)
            return `~returning~`;

        ctx.flags |= SC_CTX_FLAG_ENABLE_DEFAULT_DRIVER;
        ctx.debug_ = SC_LOG_DEBUG_NORMAL/*verbose*/;
        sc_ctx_log_to_file(ctx, toStringz(debug_file));
        if (sc_set_card_driver(ctx, "acos5_64"))
            return `~returning~`;

        rc = util_connect_card(ctx, &card, null/*opt_reader*/, 0/*opt_wait*/, 1 /*do_lock*/, `~level~`/*SC_LOG_DEBUG_NORMAL*//*verbose*/); // does: sc_lock(card) including potentially card.sm_ctx.ops.open
        mixin (log!(__FUNCTION__, " util_connect_card returning with: %d (%s)", "rc", "sc_strerror(rc)"));
//        writeln("PASSED: util_connect_card");
        scope(exit) {
            if (card) {
                if (! assumeWontThrow(Runtime.unloadLibrary(lh))) {
                    assumeWontThrow(writeln("Failed to do: Runtime.unloadLibrary(lh)"));
                    `~returning_no_card_statement~`
                }
version(Windows) {}
else {
    version(unittest) {}
    else {
                if (! assumeWontThrow(Runtime.terminate())) {
                    assumeWontThrow(writeln("Failed to do: Runtime.terminate()"));
                    `~returning_no_card_statement~`
                }
    }
}

                sc_unlock(card);
                sc_disconnect_card(card);
            }

            if (ctx)
                sc_release_context(ctx);
//            {
//                auto f = File(debug_file, "w"); // open for writing, i.e. Create an empty file for output operations. If a file with the same name already exists, its contents are discarded and the file is treated as a new empty file.
//            }
        } // scope(exit)
        if (rc || !card)
            return `~returning~`;

`~commands~`
//        return 0;
    } // disconnected from card now !
`;
}
//mixin(connect_card!(someString));


int enum_dir(int depth, sitTypeFS pos_parent, ref PKCS15Path_FileType[] collector)
{
    assert(pos_parent.node);
    assert(pos_parent.node.data.ptr);

    ubyte   fdb  = pos_parent.node.data[0];
    assert(fdb.among(EnumMembers!EFDB)); // [ EnumMembers!A ]
    ushort  fid = ub22integral(pos_parent.node.data[2..4]);
    ub2     size_or_MRL_NOR = pos_parent.node.data[4..6];
    ubyte   lcsi = pos_parent.node.data[7];
    AA["tree_fs"].SetStringId((fdb & 0x38) == 0x38? IUP_ADDBRANCH : IUP_ADDLEAF,  depth,
        format!" %04X  %s"(fid, file_type(depth, cast(EFDB)fdb, fid, size_or_MRL_NOR)));
    int rv = (cast(iup.iup_plusD.Tree) AA["tree_fs"]).SetUserId(depth+1, pos_parent.node);
    assert(rv);
    AA["tree_fs"].SetAttributeId("TOGGLEVALUE", depth+1, lcsi==5? IUP_ON : IUP_OFF);

    ubyte markedFileType = pos_parent.node.data[6];
    if (markedFileType<0xFF) {
//        writefln("This node got PKCS#15-marked: 0x[ %(%02X %) ]", pos_parent.node.data);
        with (AA["tree_fs"])
        if (markedFileType.among(PKCS15_FILE_TYPE.PKCS15_DIR, PKCS15_FILE_TYPE.PKCS15_ODF, PKCS15_FILE_TYPE.PKCS15_TOKENINFO)) {
            SetAttributeId(IUP_IMAGE,       depth+1, IUP_IMGPAPER);
            string title = GetStringId (IUP_TITLE, depth+1);
//if (markedFileType==PKCS15_FILE_TYPE.PKCS15_ODF)
//writeln("##### markedFileType==11, title: ", title);
//if (markedFileType==PKCS15_FILE_TYPE.PKCS15_TOKENINFO)
//writeln("##### markedFileType==12, title: ", title);
            SetStringId (IUP_TITLE, depth+1, title~"    "~pkcs15_names[markedFileType][0]);
        }
    }

    if (fdb.among(EFDB.CHV_EF, EFDB.Sym_Key_EF, EFDB.Purse_EF, EFDB.SE_EF))
        AA["tree_fs"].SetAttributeId(IUP_IMAGE,       depth+1, "IMGEMPTY" /*IUP_IMGEMPTY*/);

    if ((fdb & 0x38) == 0x38) {
        sc_path path;
        int pos_parent_pathLen = pos_parent.node.data[1];
        sc_path_set(&path, SC_PATH_TYPE.SC_PATH_TYPE_PATH, pos_parent.node.data.ptr+8, pos_parent_pathLen, 0, -1);

        if ((rv= sc_select_file(card, &path, null)) != SC_SUCCESS) {
            writeln("SELECT FILE failed: ", sc_strerror(rv).fromStringz);
            return rv;
        }

        ushort   SW1SW2;
        ubyte    responseLen;
        ubyte[]  response;
        if ((rv= cm_7_3_1_14_get_card_info(card, card_info_type.count_files_under_current_DF, 0, SW1SW2, responseLen, response)) != SC_SUCCESS) {
            writeln("FAILED: cm_7_3_1_14_get_card_info: count_files_under_current_DF");
            return rv;
        }
        assert(responseLen==0);
        foreach (ubyte fno; 0 .. cast(ubyte)SW1SW2) { // x"90 xx" ; XX is count files
            ub32 info; // acos will deliver 8 bytes: [FDB, DCB(always 0), FILE ID, FILE ID, SIZE or MRL, SIZE or NOR, SFI, LCSI]
            if ((rv= cm_7_3_1_14_get_card_info(card, card_info_type.File_Information, fno, SW1SW2, responseLen, response)) != SC_SUCCESS) {
                writeln("FAILED: cm_7_3_1_14_get_card_info: File_Information");
                return rv;
            }
            assert(responseLen==8);
            info[0..8] = response[0..8];
            info[6] = 0xFF;
//assumeWontThrow(writefln("info[2..4]: %(%02X %)", info[2..4]));
            if (!collector.empty && collector[0].path.equal(pos_parent.node.data[8..8+pos_parent.node.data[1]]~info[2..4]) ) {
//assumeWontThrow(writefln("branch: ?, %(%02X %)", collector[0].path));
                if (depth==0 && info[0]==EFDB.Transparent_EF) { // EF.DIR
//assumeWontThrow(writeln("branch: 1"));
                    ubyte expectedFileType = info[6] = collector[0].pkcs15FileType;
                    info[1] = 4;//cast(ubyte)(pos_parent.node.data[1]+2);
                    info[8..12] = collector[0].path[0..4];
                    collector = collector.remove(0);
                    ubyte detectedFileType = 0xFF;
                    readFile_wrapped(info, pos_parent.node, expectedFileType, detectedFileType, true, collector);
//assumeWontThrow(writefln("expectedFileType: %s, detectedFileType: %s, collector: ", expectedFileType, cast(PKCS15_FILE_TYPE)detectedFileType, collector));
                    assert(expectedFileType==detectedFileType);
                    // TODO mark previously appended childs, if required
                }
                else if (info[0]==EFDB.DF) { // EF.APP
//assumeWontThrow(writeln("branch: 2"));
                    ubyte expectedFileType = info[6] = collector[0].pkcs15FileType; // FIXME that assumes, there is 1 app only
                    assert(expectedFileType==PKCS15_FILE_TYPE.PKCS15_APPDF);
                    info[1] = cast(ubyte)(pos_parent.node.data[1]+2);
                    info[8..8+info[1]] = collector[0].path[0..info[1]];

    foreach (ub2 fid2; chunks(info[8..8+info[1]], 2)) {
//        ubyte[MAX_FCI_GET_RESPONSE_LEN] rbuf;
        fci_se_info  info2;
        rv= acos5_64_short_select(card, &info2, fid2, false/*, rbuf*/);
        info[24..32] = info2.sac[];
//        assumeWontThrow(writefln("fci: 0X[ %(%02X %) ]", rbuf));
    }

                    collector = collector.remove(0);
                    assert(collector.empty);
                    uba path5032 = info[8..8+info[1]]~[ubyte(0x50), ubyte(0x32)];
                    collector ~= [ PKCS15Path_FileType( path5032, PKCS15_FILE_TYPE.PKCS15_TOKENINFO ) ];
                    uba path5031 = info[8..8+info[1]]~[ubyte(0x50), ubyte(0x31)];
                    collector ~= [ PKCS15Path_FileType( path5031, PKCS15_FILE_TYPE.PKCS15_ODF ) ];
//assumeWontThrow(writeln(collector));
                }
                else if (info[0]==EFDB.Transparent_EF && pos_parent.node.data[6]==PKCS15_FILE_TYPE.PKCS15_APPDF) { // EF.PKCS15_ODF
//assumeWontThrow(writeln("branch: 3"));
//assumeWontThrow(writeln(collector));
                    ubyte expectedFileType = info[6] = collector[0].pkcs15FileType;
                    info[1] = cast(ubyte)(pos_parent.node.data[1]+2);
                    info[8..8+info[1]] = collector[0].path[0..info[1]];
                    ubyte detectedFileType = 0xFF;
//                    PKCS15Path_FileType[] pkcs15Extracted;
                    readFile_wrapped(info, pos_parent.node, expectedFileType, detectedFileType, true, collector);
//assumeWontThrow(writeln("detectedFileType: ", cast(PKCS15_FILE_TYPE)detectedFileType,", collector: ",collector));
                    collector = collector.remove(0);
                    assert(expectedFileType==detectedFileType);
//assumeWontThrow(writeln(collector));
                }
            } // if (!collector.empty && collector[0].path.equal...
            fs.append_child(pos_parent, info);
        }

        foreach_reverse (node, unUsed; fs.siblingRange(pos_parent.begin(), pos_parent.end())) {
            assert(node);
            int j = 8+pos_parent_pathLen;
            node.data[8..j] = pos_parent.node.data[8..j];
            node.data[j..j+2] = node.data[2..4];
            node.data[1] = cast(ubyte)(pos_parent_pathLen+2);
            assert(node.data[1] > 0  &&  node.data[1] <= 16  &&  node.data[1]%2 == 0);
            if ((rv= enum_dir(depth + 1, new sitTypeFS(node), collector)) != SC_SUCCESS)
                return rv;
        }
    }
    return 0;
} // int enum_dir

/*
enum_dir does already some PKCS#15-related processing (but only what fits in the workflow of enum_dir: It doesn't jump back to files already processed as tree nodes):
read 2F00 EF.DIR -> mark e.g. 3F004100 as PKCS15_APPDF
  only if 3F004100 exists and is marked, then
    insert 3F0041005031 and 3F0041005032 and read PKCS15_ODF, store extracted in collector

this will do the remaining, based on the information collected in collector,
assuming, the files collected are children of e.g. 3F004100 as PKCS15_APPDF
*/
int post_process(/*sitTypeFS pos_parent,*/ ref PKCS15Path_FileType[] collector) {
    /* assuming there is 1 aooDF only */
    appdf = fs.preOrderRange(fs.begin(), fs.end()).locate!"a[6]==b"(PKCS15_FILE_TYPE.PKCS15_APPDF);
    assert(appdf);
//    TreeTypeFS.nodeType* appdf = fs.preOrderRange(fs.begin(), fs.end()).locate!"a[6]==b"(PKCS15_FILE_TYPE.PKCS15_APPDF);
//    assert(appdf);
    // unroll/read the DF files
    sitTypeFS parent = new sitTypeFS(appdf);
    with (PKCS15_FILE_TYPE)
    foreach (tnTypePtr nodeFS, unUsed; fs.siblingRange(parent.begin(), parent.end())) {
        ubyte len = nodeFS.data[1];
        assert(len>2 && len<=16 && len%2==0);
        ptrdiff_t  c_pos = countUntil!((a,b) => a.pkcs15FileType<=PKCS15_AODF && a.path.equal(b))(collector, nodeFS.data[8..8+len]);
//assumeWontThrow(writefln("pos: %s,\t %(%02X %)", c_pos, pointer.data));
        if (c_pos>=0) {
            ubyte expectedFileType = nodeFS.data[6] = collector[c_pos].pkcs15FileType;
            assert(expectedFileType.among(EnumMembers!PKCS15_FILE_TYPE) && expectedFileType!=PKCS15_NONE);
            ubyte detectedFileType = 0xFF;
            readFile_wrapped(nodeFS.data, nodeFS, expectedFileType, detectedFileType, expectedFileType.among(/*PKCS15_AODF, PKCS15_SKDF*/255)? false : true, collector);
            assert(detectedFileType.among(EnumMembers!PKCS15_FILE_TYPE));
            assert(expectedFileType==detectedFileType); // TODO think about changing to e.g. throw an exception and inform user what exactly is wrong
//if (expectedFileType!=detectedFileType)
//writefln("### expectedFileType(%s), detectedFileType(%s)", expectedFileType, detectedFileType);
            // file xy was expected to have ASN.1 encoded content of PKCS#15 type z0, but the content inspection couldn't verify that (detected was PKCS#15 type z1)
            collector = collector.remove(c_pos);
            if (expectedFileType<0xFF) {
//                writefln("This node got PKCS#15-marked: 0x[ %(%02X %) ]", nodeFS.data);
                with (cast(iup.iup_plusD.Tree) AA["tree_fs"]) {
                    int nodeID = GetId(nodeFS);
                    SetAttributeId(IUP_IMAGE, nodeID, expectedFileType<=PKCS15_AODF || expectedFileType.among(PKCS15_ODF, PKCS15_TOKENINFO, PKCS15_UNUSED) ? IUP_IMGPAPER : IUP_IMGBLANK);
                    if (expectedFileType==detectedFileType) {
                        string title = GetStringId (IUP_TITLE, nodeID);
                        SetStringId (IUP_TITLE, nodeID, title~"    "~pkcs15_names[expectedFileType][0]);
                    }
                }
            }
        }
    }
//assumeWontThrow(writeln(collector));
    // read and mark the collector files; all files referring to others should have been processed already !
    with (PKCS15_FILE_TYPE)
    foreach (tnTypePtr nodeFS, unUsed; fs.siblingRange(parent.begin(), parent.end())) {
        ubyte len = nodeFS.data[1];
        assert(len>2 && len<=16 && len%2==0);
        ptrdiff_t  c_pos = countUntil!((a,b) => a.pkcs15FileType>PKCS15_AODF && a.pkcs15FileType<PKCS15_NONE && a.path.equal(b))(collector, nodeFS.data[8..8+len]);
//assumeWontThrow(writefln("pos: %s,\t %(%02X %)", c_pos, pointer.data));
        if (c_pos>=0) {
            ubyte expectedFileType = nodeFS.data[6] = collector[c_pos].pkcs15FileType;
            assert(expectedFileType.among(EnumMembers!PKCS15_FILE_TYPE) && expectedFileType!=PKCS15_NONE);
            ubyte detectedFileType = 0xFF;
            readFile_wrapped(nodeFS.data, nodeFS, expectedFileType, detectedFileType, false /*don't extract*/, collector);
            assert(detectedFileType.among(EnumMembers!PKCS15_FILE_TYPE));
            // PKCS15_RSAPrivateKey should be undetectable by reading
            if (nodeFS.data[0]==EFDB.RSA_Key_EF && expectedFileType==PKCS15_RSAPrivateKey) detectedFileType = expectedFileType;
//            assert(expectedFileType==detectedFileType); // TODO think about changing to e.g. throw an exception and inform user what exactly is wrong
            // file xy was expected to have ASN.1 encoded content of PKCS#15 type z0, but the content inspection couldn't verify that (detected was PKCS#15 type z0
if (expectedFileType!=detectedFileType)
writefln("### expectedFileType(%s), detectedFileType(%s)", expectedFileType, detectedFileType);
            collector = collector.remove(c_pos);

            if (expectedFileType<0xFF) {
//                writefln("This node got PKCS#15-marked: 0x[ %(%02X %) ]", nodeFS.data);
                with (cast(iup.iup_plusD.Tree) AA["tree_fs"]) {
                    int nodeID = GetId(nodeFS);
                    SetAttributeId(IUP_IMAGE, nodeID, expectedFileType<=PKCS15_AODF || expectedFileType.among(PKCS15_ODF, PKCS15_TOKENINFO, PKCS15_UNUSED) ? IUP_IMGPAPER : IUP_IMGBLANK);
                    if (expectedFileType==detectedFileType || nodeFS.data[0]==EFDB.RSA_Key_EF) {
                        string title = GetStringId (IUP_TITLE, nodeID);
                        SetStringId (IUP_TITLE, nodeID, title~"    "~pkcs15_names[expectedFileType][0]);
                    }
                }
            }
        }
    }
//assumeWontThrow(writeln(collector));
    foreach (tnTypePtr nodeFS, unUsed; fs.preOrderRange(fs.begin(), fs.end()) ) {
        try
        with (cast(iup.iup_plusD.Tree) AA["tree_fs"])
        if (nodeFS.data[0]==EFDB.RSA_Key_EF) {
            int nodeID = GetId(nodeFS);
            string title = GetStringId (IUP_TITLE, nodeID);
            if (title.endsWith!(a => a=='B'))
                SetStringId (IUP_TITLE, nodeID, title~"    EF(RSA)");
        }
        catch(Exception e) {}
    }
    return 0;
}

/*
  calling acos5_64 exported function(s) directly requires a context/card handle from opensc
  will be logged to "/tmp/opensc-debug.log", section "acos5_64_gui"
  populate the gui tree of card file system

  FIXME: overhaul the processing started by populate_tree_fs: It shouldn't depend on the order of files reported by cm_7_3_1_14_get_card_info(card, card_info_type.File_Information ...
*/
int populate_tree_fs()
{
    int rv, id=1;
    with (AA["tree_fs"]) {
        SetAttribute(IUP_TITLE, " file system");  // 0  depends on ADDROOT's default==YES
        SetAttribute("TOGGLEVISIBLE", IUP_NO);
    }
//// read 3F00 for correct '8byte info ! This will also make sure, we have a file system, otherwise return
    ub32  rootFS = [0x3F, 0x2, 0x3F, 0x0,  0x0, 0x0, 0xFF, 0x0,   0x3F, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
        0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0]; // the last 2 bytes are incorrect
    fs = TreeTypeFS(rootFS);
//writefln("head(%s), head.nextSibling(%s), feet(%s), *head.nextSibling(%s)", fs.head, fs.head.nextSibling, fs.feet, *(fs.head.nextSibling)); // 0x[%(%02X %)]
//    ub8 info = [0x3F, 0, 0x3F, 0, 0,0,0,0]; // acos will deliver 8 bytes: [FDB, DCB(always 0), FILE ID, FILE ID, SIZE or MRL, SIZE or NOR, SFI, LCSI]
    auto pos_root = new sitTypeFS(fs.begin().node);

    uba path2F00 = [0x3F, 0x0, 0x2F, 0x0];
    PKCS15Path_FileType[] collector = new PKCS15Path_FileType[0]; // = [ PKCS15Path_FileType( path2F00, PKCS15_FILE_TYPE.PKCS15_DIR ) ];
    if (doCheckPKCS15)
        collector ~= PKCS15Path_FileType( path2F00, PKCS15_FILE_TYPE.PKCS15_DIR );
    rv = enum_dir(0,  pos_root.dup, collector);
    if (!collector.empty)
        rv = post_process(/*pos_root.dup,*/ collector);

    return rv;
}


void readFile_wrapped(ubyte[] info, tnTypePtr pn, const ubyte expectedFileType, ref ubyte detectedFileType, bool doExtract, ref PKCS15Path_FileType[] collector) {
    assert(info[1]);
    int rv;
    foreach (ub2 fid2; chunks(info[8..8+info[1]], 2)) {
//        ubyte[MAX_FCI_GET_RESPONSE_LEN] rbuf;
        fci_se_info  info2;
        rv= acos5_64_short_select(card, &info2, fid2, false/*, rbuf*/);
        info[24..32] = info2.sac;
//        assumeWontThrow(writefln("fci: 0X[ %(%02X %) ]", rbuf));
    }

    PKCS15Path_FileType[]  pkcs15Extracted;
    ub2  fid2 = info[2..4];
    EFDB fdb2 = cast(EFDB) info[0];
    ub2  size_or_MRL_NOR = info[4..6];
/*
    assumeWontThrow(writeln(pos_parent.node)); // 7FC0B8C46700
    assumeWontThrow(writeln(fid2)); //  [0x2F, 0]
    assumeWontThrow(writeln(fdb2)); // Transparent_EF
    assumeWontThrow(writeln(decompose(fdb2, size_or_MRL_NOR)[0])); // 33
*/
    readFile(pn, fid2, fdb2, decompose(fdb2, size_or_MRL_NOR).expand, info[6], detectedFileType, pkcs15Extracted, doExtract);
//assumeWontThrow(writeln(detectedFileType, pkcs15Extracted));
    with (PKCS15_FILE_TYPE) if (!detectedFileType.among(PKCS15_SKDF, PKCS15_AODF))
    foreach (e; pkcs15Extracted.uniq!"a.path.equal(b.path)")
        collector ~= e;
//assumeWontThrow(writeln(collector));
} // readFile_wrapped

/*
call from populate_list_op_file_possible:
selectbranchleaf_cb(Ihandle* ih, int id, int status)
    populate_list_op_file_possible(pn, info.fid, cast(EFDB)info.fdb, size_or_MRL_NOR, pn.data[7], info.sac);
        readFile(pn, fid, fdb, decompose(fdb, size_or_MRL_NOR).expand, expectedFileType, detectedFileType, pkcs15Extracted);
*/
void readFile(tnTypePtr pn, ub2 fid, EFDB fdb, ushort size, ubyte mrl, ubyte nor, ubyte expectedFileType, ref ubyte PKCS15fileType, out PKCS15Path_FileType[] pkcs15Extracted, bool doExtract=false) nothrow
{
//assumeWontThrow(writefln("readFile(ub2 %s, EFDB %s, expectedFileType %s)", fid, fdb, expectedFileType));
    with (EFDB)
    if (!fdb.among(Transparent_EF, Linear_Fixed_EF, Linear_Variable_EF, Cyclic_EF, RSA_Key_EF /*omit reading CHV_EF, Sym_Key_EF*/, Purse_EF, SE_EF))
        return;

    Handle h = AA["fs_text"];
    ubyte[] buf = new ubyte[size? size : mrl];
    ubyte* response;
    size_t responselen;
    int rv;
    uint[] offsetTable = [0];

    with (EFDB)
    switch (fdb) {
        case Transparent_EF:
            rv = sc_read_binary(card, 0, buf.ptr, buf.length, 0 /*flags*/);
            assert(rv>0 && rv==buf.length);
//assumeWontThrow(writefln("0x[%(%02X %)]", buf));
//            if (buf[0] == 0)
//                return;
            while (buf.length>=5 && !any(buf[$-5..$]))
                buf.length = buf.length-1;
            foreach (chunk; chunks(buf, 48)) {
//assumeWontThrow(writefln("0x[%(%02X %)]", chunk));
                h.SetString("APPEND",  assumeWontThrow(format!"%(%02X %)"(chunk)));
            }

            int xLen;
            while (offsetTable[$-1] < size  &&  buf[offsetTable[$-1]] != 0)
                offsetTable ~= min( cast(uint) (offsetTable[$-1]+1+ asn1_get_length_der(buf[offsetTable[$-1]+1..$],xLen)+xLen), size );
//              offsetTable ~= min(cast(uint) ( offsetTable[$-1]+ decodedLengthOctets(buf, offsetTable[$-1]+1) ), size);

            if (offsetTable.length<2)
                offsetTable ~= cast(uint)buf.length;
//assumeWontThrow(writefln("offsetTable[0]: %s, offsetTable[$-1]: %s", offsetTable[0], offsetTable[$-1]));
            break;
        case Linear_Fixed_EF, Linear_Variable_EF, SE_EF:
            foreach (rec_idx; 1 .. 1+nor) {
                if (fdb==SE_EF)
                    buf = new ubyte[size? size : mrl];
                else
                    buf[] = 0;
                rv = sc_read_record(card, rec_idx, buf.ptr, buf.length, 0 /*flags*/);
                assert(rv>0 && rv==buf.length);
//assumeWontThrow(writefln("0x[%(%02X %)]", buf));
                h.SetString("APPEND", "Record "~rec_idx.to!string);
                if (fdb==SE_EF)
                    while (buf.length && buf[$-1]==0)
                        buf.length = buf.length-1;
                foreach (chunk; chunks(buf, 48))
                    h.SetString("APPEND",  assumeWontThrow(format!"%(%02X %)"(chunk)));
            }
            // these types don't get ASN.1 decoded
            return;
        case RSA_Key_EF:
            if ((rv= sc_get_data(card, 0, buf.ptr, buf.length)) != buf.length) return;
            h.SetString("APPEND", " ");
            foreach (chunk; chunks(buf, 48)) {
//assumeWontThrow(writefln("0x[%(%02X %)]", chunk));
                h.SetString("APPEND",  assumeWontThrow(format!"%(%02X %)"(chunk)));
            }
//            assert(rv==buf.length /*rv>0 && rv <= buf.length*/);
//            assumeWontThrow(writefln("0x[%(%02X %)]", buf));
//            foreach (chunk; chunks(buf, 64))
//                assumeWontThrow(writefln([%(%02X %)]", chunk));
            if (buf[0] != 0  || !canFind(iota(4, 34, 2), buf[1]))
                return;
//assumeWontThrow(writeln(RSA_public_openssh_formatted(fid, buf)));
            AA["fs_text_asn1"].SetStringVALUE(RSA_public_openssh_formatted(fid, buf));
            {
                sc_path path;
                sc_path_set(&path, SC_PATH_TYPE.SC_PATH_TYPE_PATH, pn.data.ptr+8, pn.data[1], 0, -1);
                if ((rv= card.ops.read_public_key(card, SC_ALGORITHM_RSA, &path, 0, decode_key_RSA_ModulusBitLen(buf[1]), &response, &responselen)) != SC_SUCCESS) return;
                offsetTable ~= cast(uint)responselen;
                string PEM = "\n-----BEGIN RSA PUBLIC KEY-----\n";
                PEM ~= Base64.encode(response[0..responselen]) ~ "\n-----END RSA PUBLIC KEY-----\n";
                AA["fs_text_asn1"].SetString("APPEND", PEM);
//assumeWontThrow(writefln("0x[%(%02X %)]", response[0..responselen]));
            }

            break;
        default:
            rv = -1;
            break;
    }

    assert(offsetTable.length>=2);
//    assumeWontThrow(writeln(offsetTable));
    int  asn1_result;
    string[] outStructure;

    with (PKCS15_FILE_TYPE)
    if (expectedFileType.among(PKCS15_DIR, PKCS15_ODF, PKCS15_TOKENINFO,
            PKCS15_PRKDF, PKCS15_PUKDF, PKCS15_PUKDF_TRUSTED,  PKCS15_SKDF, PKCS15_CDF, PKCS15_CDF_TRUSTED, PKCS15_CDF_USEFUL, PKCS15_DODF, PKCS15_AODF,
            PKCS15_Cert, PKCS15_RSAPublicKey))
    foreach (sw; offsetTable.slide(2)) { // sw: SlideWindow
        asn1_node  structure;
        asn1_result = asn1_create_element(PKCS15, pkcs15_names[expectedFileType][doExtract? 1 : 3], &structure);
        scope(exit)
            asn1_delete_structure(&structure);
        if (asn1_result != ASN1_SUCCESS) {
            assumeWontThrow(writeln("### Structure creation: ", asn1_strerror2(asn1_result)));
            continue;
        }
        asn1_result = asn1_der_decoding(&structure, fdb==EFDB.RSA_Key_EF? response[0..responselen] : buf[sw[0]..sw[1]], errorDescription);
        if (asn1_result != ASN1_SUCCESS) {
            assumeWontThrow(writeln("### asn1Decoding: ", errorDescription));
            continue;
        }
        PKCS15fileType = expectedFileType;
        ubyte[16]  str;
        int        outLen;

        switch (expectedFileType) {
            case PKCS15_DIR:
                if (doExtract) {
                    if ((asn1_result= asn1_read_value(structure, pkcs15_names[expectedFileType][2], str, outLen)) != ASN1_SUCCESS)
                        goto looptail;
                    pkcs15Extracted ~= PKCS15Path_FileType(str[0..outLen].dup, PKCS15_APPDF);
                }
                break;

            case PKCS15_ODF:
                if (doExtract)
                    foreach (PKCS15_FILE_TYPE i; PKCS15_PRKDF..PKCS15_RSAPublicKey /*==PKCS15_AODF+1*/)
                        if (asn1_read_value(structure, pkcs15_names[i][2], str, outLen) == ASN1_SUCCESS) {
                            pkcs15Extracted ~= PKCS15Path_FileType(str[0..outLen].dup, i);
                            break;
                        }
                break;

            case PKCS15_PRKDF:
                if (doExtract) {
                    PRKDF ~= PKCS15_ObjectTyp(sw[0], sw[1], buf[sw[0]..sw[1]], null, asn1_dup_node(structure, ""), null);
                    if ((asn1_result= asn1_read_value(structure, pkcs15_names[PKCS15_RSAPrivateKey][2], str, outLen)) != ASN1_SUCCESS)
                        goto looptail;
                    pkcs15Extracted ~= PKCS15Path_FileType(str[0..outLen].dup, PKCS15_RSAPrivateKey);
                }
                break;

            case PKCS15_PUKDF, PKCS15_PUKDF_TRUSTED:
                if (doExtract) {
                    switch (expectedFileType) {
                        case PKCS15_PUKDF:
                            PUKDF         ~= PKCS15_ObjectTyp(sw[0], sw[1], buf[sw[0]..sw[1]], null, asn1_dup_node(structure, ""), null);
                            break;
                        case PKCS15_PUKDF_TRUSTED:
                            PUKDF_TRUSTED ~= PKCS15_ObjectTyp(sw[0], sw[1], buf[sw[0]..sw[1]], null, asn1_dup_node(structure, ""), null);
                            break;
                        default: assert(0);
                    }
                    if ((asn1_result= asn1_read_value(structure, pkcs15_names[PKCS15_RSAPublicKey][2], str, outLen)) != ASN1_SUCCESS)
                        goto looptail;
                    pkcs15Extracted ~= PKCS15Path_FileType(str[0..outLen].dup, PKCS15_RSAPublicKey);
                }
                break;

            case PKCS15_CDF, PKCS15_CDF_TRUSTED, PKCS15_CDF_USEFUL:
                if (doExtract) {
                        switch (expectedFileType) {
                            case PKCS15_CDF:
                                CDF         ~= PKCS15_ObjectTyp(sw[0], sw[1], buf[sw[0]..sw[1]], null, asn1_dup_node(structure, ""), null);
                                break;
                            case PKCS15_CDF_TRUSTED:
                                CDF_TRUSTED ~= PKCS15_ObjectTyp(sw[0], sw[1], buf[sw[0]..sw[1]], null, asn1_dup_node(structure, ""), null);
                                break;
                            case PKCS15_CDF_USEFUL:
                                CDF_USEFUL  ~= PKCS15_ObjectTyp(sw[0], sw[1], buf[sw[0]..sw[1]], null, asn1_dup_node(structure, ""), null);
                                break;

                            default: assert(0);
                        }
                        if ((asn1_result= asn1_read_value(structure, pkcs15_names[PKCS15_Cert][2], str, outLen)) != ASN1_SUCCESS)
                            goto looptail;
                        pkcs15Extracted ~= PKCS15Path_FileType(str[0..outLen].dup, PKCS15_Cert);
                }
                break;

            case PKCS15_DODF:
                if (doExtract) {
                    DODF  ~= PKCS15_ObjectTyp(sw[0], sw[1], buf[sw[0]..sw[1]], null, asn1_dup_node(structure, ""), null);
                    if ((asn1_result= asn1_read_value(structure, pkcs15_names[PKCS15_Data][2], str, outLen)) != ASN1_SUCCESS)
                        goto looptail;
                    pkcs15Extracted ~= PKCS15Path_FileType(str[0..outLen].dup, PKCS15_Data);
                }
                break;

            case PKCS15_SKDF:
                if (doExtract) // all keys of an app are in a well-known file (records)
                    SKDF  ~= PKCS15_ObjectTyp(sw[0], sw[1], buf[sw[0]..sw[1]], null, asn1_dup_node(structure, ""), null);
                break;

            case PKCS15_AODF:
                if (doExtract) // all pins of an app are in a well-known file (records)
                    AODF  ~= PKCS15_ObjectTyp(sw[0], sw[1], buf[sw[0]..sw[1]], null, asn1_dup_node(structure, ""), null);
                break;

            case PKCS15_Cert, PKCS15_RSAPublicKey, PKCS15_TOKENINFO:
                break;

            default:  assert(0);
        } // switch (expectedFileType)

        version(Posix)
        if (!doExtract)
            asn1_visit_structure (outStructure, structure, pkcs15_names[expectedFileType][4], ASN1_PRINT_NAME_TYPE_VALUE, &someScanner);

        AA["fs_text_asn1"].SetString("APPEND", " ");
        foreach (line; outStructure)
            AA["fs_text_asn1"].SetString("APPEND", line);
        continue;
looptail: // jump target, if asn1_read_value failed, saving some code duplication
        assumeWontThrow(writeln("### asn1_read_value: ", asn1_strerror2(asn1_result)));
    } // foreach (sw; offsetTable.slide(2)) {
} // readFile


string RSA_public_openssh_formatted(ub2 fid, scope const ubyte[] rsa_raw_acos5_64) nothrow
{
    import std.digest.md;
    import std.digest.sha;

    if (rsa_raw_acos5_64[0] != 0  ||  rsa_raw_acos5_64[1] == 0) // no public key
        return "";
    string prolog;
    ubyte[] pre_openssh = [0,0,0,7, 0x73, 0x73, 0x68, 0x2D, 0x72, 0x73, 0x61,
                           0,0,0,0];
    bool valid = rsa_raw_acos5_64[4] == 3;
    ushort modLenBytes = decode_key_RSA_ModulusBitLen(rsa_raw_acos5_64[1])/8;
    prolog = "\nThis is a "~(valid?"":"in")~"valid "~to!string(modLenBytes*8)~" bit public RSA key with file id 0x " ~ toHexString!(Order.increasing,LetterCase.upper)(fid)~
        " (it's partner private key file id is 0x " ~ toHexString!(Order.increasing,LetterCase.upper)(rsa_raw_acos5_64[2..4]) ~ ") :\n\n";
    ptrdiff_t  e_len =  rsa_raw_acos5_64[5..21].countUntil!"a>0"; //16- rsa_raw_acos5_64[5..21].until!"a>0"[].length;
    assert(e_len != -1); // exponent MUST NOT be zero! e_len>=0 && e_len<=15
    e_len = 16 - e_len;
    pre_openssh[$-1] = cast(ubyte) e_len;
    assert(rsa_raw_acos5_64.length >= 21+modLenBytes);
    pre_openssh ~= rsa_raw_acos5_64[21-e_len .. 21] ~ integral2ub!4(modLenBytes);
    if (rsa_raw_acos5_64[21] & 0x80) {
        pre_openssh ~= 0;
        ++pre_openssh[$-2];
    }
    pre_openssh ~= rsa_raw_acos5_64[21..21+modLenBytes];
    string result = assumeUnique(Base64.encode(pre_openssh));

    auto md5 = new MD5Digest();
    ubyte[] hashMD5 = md5.digest(pre_openssh);
    string fingerprintMD5 = toHexString!(LetterCase.lower)(hashMD5);
//    assumeWontThrow(writeln(fingerprintMD5)); // "2d 0d 76 4f 21 ea fb e1 27 98 f0 14 8b 56 35 0c"
    auto sha256 = new SHA256Digest();
    ubyte[] hashSHA256 = sha256.digest(pre_openssh);
    string fingerprintSHA256 = assumeUnique(Base64.encode(hashSHA256));

    return prolog~"ssh-rsa "~result~ "  comment_file_" ~ toHexString!(Order.increasing,LetterCase.upper)(fid) ~
        "\n\nThe fingerprint (MD5) is: "~fingerprintMD5~"\n\nThe fingerprint (SHA256) base64-encoded is: "~fingerprintSHA256;
}


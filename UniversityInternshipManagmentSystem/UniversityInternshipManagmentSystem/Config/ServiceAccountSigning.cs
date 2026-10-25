using System;
using System.Security.Cryptography;
using System.Text;

namespace UniversityInternshipManagmentSystem.Config
{
    // Signs text with the private key of the Firebase admin key file (RSA + SHA256).
    //
    // The key is used in memory only. The usual way (RSACng / CngKey.Import) can fail on shared hosting, where the
    // website has no Windows user profile to keep the key in, and then the pages that need the admin key stop working.
    internal static class ServiceAccountSigning
    {
        // pem = the "private_key" text of the key file ("-----BEGIN PRIVATE KEY-----" ...)
        public static byte[] Sign(string text, string pem)
        {
            RSAParameters key = ReadPrivateKey(pem);

            var options = new CspParameters(24) { Flags = CspProviderFlags.CreateEphemeralKey | CspProviderFlags.NoPrompt };   // 24 = the provider that can do SHA256
            using (var rsa = new RSACryptoServiceProvider(options))
            {
                rsa.PersistKeyInCsp = false;
                rsa.ImportParameters(key);
                return rsa.SignData(Encoding.UTF8.GetBytes(text), "SHA256");
            }
        }

        // Google gives the key as PKCS#8: a few nested DER blocks that end with the numbers of the RSA key.
        //   PrivateKeyInfo = { version, algorithm, OCTET STRING( RSAPrivateKey = { version, n, e, d, p, q, dp, dq, qinv } ) }
        private static RSAParameters ReadPrivateKey(string pem)
        {
            string base64 = pem.Replace("-----BEGIN PRIVATE KEY-----", "").Replace("-----END PRIVATE KEY-----", "")
                .Replace("\r", "").Replace("\n", "").Trim();
            byte[] info = Convert.FromBase64String(base64);

            int at = 0;
            StepInto(info, ref at, 0x30);                       // PrivateKeyInfo
            ReadBlock(info, ref at, 0x02);                      // version
            ReadBlock(info, ref at, 0x30);                      // algorithm (RSA)
            byte[] rsaKey = ReadBlock(info, ref at, 0x04);      // the RSA key, wrapped in an octet string

            at = 0;
            StepInto(rsaKey, ref at, 0x30);                     // RSAPrivateKey
            ReadBlock(rsaKey, ref at, 0x02);                    // version
            byte[] modulus = ReadNumber(rsaKey, ref at);
            int half = (modulus.Length + 1) / 2;

            return new RSAParameters
            {
                Modulus = modulus,
                Exponent = ReadNumber(rsaKey, ref at),
                D = Pad(ReadNumber(rsaKey, ref at), modulus.Length),
                P = Pad(ReadNumber(rsaKey, ref at), half),
                Q = Pad(ReadNumber(rsaKey, ref at), half),
                DP = Pad(ReadNumber(rsaKey, ref at), half),
                DQ = Pad(ReadNumber(rsaKey, ref at), half),
                InverseQ = Pad(ReadNumber(rsaKey, ref at), half)
            };
        }

        // Reads the tag and the length of a block and stays INSIDE it (the next read is the first thing in the block)
        private static void StepInto(byte[] data, ref int at, byte tag)
        {
            if (data[at++] != tag) throw new CryptographicException("The Firebase admin key is not in the expected format.");
            ReadLength(data, ref at);
        }

        // Reads a whole block and returns what is inside it
        private static byte[] ReadBlock(byte[] data, ref int at, byte tag)
        {
            if (data[at++] != tag) throw new CryptographicException("The Firebase admin key is not in the expected format.");
            int length = ReadLength(data, ref at);
            byte[] value = new byte[length];
            Buffer.BlockCopy(data, at, value, 0, length);
            at += length;
            return value;
        }

        // The length is one byte (under 128), or 0x81 / 0x82 / ... followed by that many bytes
        private static int ReadLength(byte[] data, ref int at)
        {
            int first = data[at++];
            if (first < 0x80) return first;

            int count = first & 0x7F, length = 0;
            for (int i = 0; i < count; i++) length = (length << 8) | data[at++];
            return length;
        }

        // A whole number, without the zero byte that DER puts in front of numbers that start with a high bit
        private static byte[] ReadNumber(byte[] data, ref int at)
        {
            byte[] value = ReadBlock(data, ref at, 0x02);
            if (value.Length > 1 && value[0] == 0)
            {
                byte[] trimmed = new byte[value.Length - 1];
                Buffer.BlockCopy(value, 1, trimmed, 0, trimmed.Length);
                return trimmed;
            }
            return value;
        }

        // The numbers of an RSA key must have an exact length: add zeros in front when it is shorter
        private static byte[] Pad(byte[] value, int size)
        {
            if (value.Length >= size) return value;
            byte[] padded = new byte[size];
            Buffer.BlockCopy(value, 0, padded, size - value.Length, value.Length);
            return padded;
        }
    }
}

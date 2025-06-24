package com.dell.isgedge.hzp.tests;

import static org.assertj.core.api.Assertions.assertThat;

import com.dell.isgedge.qa.commons.exceptions.QAException;
import com.dell.isgedge.qa.commons.websockets.Client;
import java.io.*;
import java.net.URI;
import java.net.URISyntaxException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.UnrecoverableKeyException;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.List;
import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManagerFactory;
import org.apache.http.HttpResponse;
import org.apache.http.client.methods.HttpPost;
import org.apache.http.conn.ssl.SSLConnectionSocketFactory;
import org.apache.http.impl.client.CloseableHttpClient;
import org.apache.http.impl.client.HttpClients;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.testng.annotations.Test;

/**
 * Pre-requisites - Before running this test, make sure to add the below hosts to the /etc/hosts
 * file on your EO default.dell.com edge.rendezvous.dell.com edge.rendezvous.local.1
 * edge.rendezvous.local.2 edge.rendezvous.local.3 rv-internal-use-only rendezvous
 * mtls.edge.internal.use.only
 *
 * <p>- Need to generate ca.crt, client.crt, keystore.jks and keystore_inv.jks before and copy them
 * in resources folder
 */
public class MTLSAndTLSTests {

  private static final Logger LOG = LoggerFactory.getLogger(MTLSAndTLSTests.class);
  private static final String PROTOCOL = "TLSv1.3";
  private static final String X509 = "X.509";
  private static final String CIPHER_SUITES[] = {"TLS_AES_256_GCM_SHA384"};
  private static final char[] KEYPASS_AND_STOREPASS_VALUE = "password".toCharArray();
  private static final String HOST_mTLS_DELL = "https://mtls.edge.internal.use.only";
  private static final String HOST_DEFAULT_DELL = "https://default.dell.com";
  private static final String HOST_DEFAULT_DELL_WITHOUT_HTTPS = "http://default.dell.com";
  private static final List<String> HOSTS_FDO_RV =
      List.of(
          "https://rv.dell.com",
          "https://rv.local.edge",
          "https://rv1.local.edge",
          "https://rv2.local.edge");
  private static final List<String> TLS_ECE_ENDPOINTS =
      List.of("/oe-template-mgr/api/v1/templatemanager", "/repository");
  private static final List<String> TLS_NON_ECE_ENDPOINTS =
      List.of(
          "/fdo/101/msg/60",
          "/security/api/v1/onboarding",
          "/catalog/api/v1/catalog",
          "/inventory/api/v1/eceinventory");
  private static final List<String> mTLS_ECE_ENDPOINTS =
      List.of(
          "/oe-template-mgr/api/v1/templatemanager",
          "/datacollection/api/v1/datacollection",
          "/repository");
  private static String TLS_FDO_RV_NON_ECE_ENDPOINT = "/fdo/101/msg/30";
  private static String ERROR_MISSING_CERTIFICATE =
      "unable to find valid certification path to requested target";
  private static final String WSS_URI = "wss://mtls.edge.internal.use.only/nats";
  private static final String WSS_URI_SECOND_NATS = "wss://mtls.edge.internal.use.only/metrics";
  private static String ERROR_CONNECTION_REFUSED = "Connection refused";
  private static final byte[] CA_CERT_BYTES;
  private static final byte[] TLS_CA_CERT_BYTES;
  private static final byte[] CLIENT_KEYSTORE_BYTES;
  private static final byte[] CLIENT_CERT_BYTES;
  private static final byte[] CLIENT_KEYSTORE_INV_BYTES;
  private static final String host_ip = System.getenv("EO_IP");

  static {
    try {
      Path dataPath = Paths.get("/data/certs/");
      CA_CERT_BYTES = Files.readAllBytes(dataPath.resolve("mtls_ca.crt"));
      TLS_CA_CERT_BYTES = Files.readAllBytes(dataPath.resolve("tls_ca.crt"));
      CLIENT_KEYSTORE_BYTES = Files.readAllBytes(dataPath.resolve("keystore.jks"));
      CLIENT_KEYSTORE_INV_BYTES = Files.readAllBytes(dataPath.resolve("keystore_invalid.jks"));
      CLIENT_CERT_BYTES = Files.readAllBytes(dataPath.resolve("client.crt"));
    } catch (IOException e) {
      throw new RuntimeException(e);
    }
  }

  /**
   * Verify ECE-only endpoints can connect with mTLS with a valid client certificate
   *
   * <p><a>
   * href=https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=0&id=3991359>TC-5113</a>
   */
  @Test
  public void verifyEceOnlyEndpointsMTLS() throws Exception {
    LOG.info("Running verifyEceOnlyEndpointsMTLS test");
    for (String eceEndpoint : mTLS_ECE_ENDPOINTS) {
      LOG.info("Verify Ece only endpoint mTLS: {}{}", HOST_mTLS_DELL, eceEndpoint);
      assertThat(
              callEndpoint(
                  createHttpClient(
                      new ByteArrayInputStream(CLIENT_KEYSTORE_BYTES),
                      new ByteArrayInputStream(CA_CERT_BYTES),
                      true),
                  HOST_mTLS_DELL + eceEndpoint))
          .isNotIn(503, 525);
    }
  }

  /**
   * Verify NATS can connect with mTLS with a valid client certificate
   *
   * <p><a>
   * href=https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=0&id=3991359>TC-5113</a>
   */
  @Test
  public void verifyNatsForMTLS() throws Exception {
    LOG.info("Running verifyNatsForMTLS test");
    SSLContext sslContext =
        createSSLContext(
            new ByteArrayInputStream(CLIENT_KEYSTORE_BYTES),
            new ByteArrayInputStream(CA_CERT_BYTES),
            true);
    try {
      Client client = new Client(new URI(WSS_URI));
      SSLSocketFactory factory = sslContext.getSocketFactory();
      client.setSocketFactory(factory);
      client.connectBlocking();
      client.send("Hello NATS!");
      LOG.info("message sent");
    } catch (URISyntaxException | InterruptedException e) {
      throw new QAException("Not able to connect to NATs", e);
    }
  }

  /** Verify NATS can connect with mTLS and a valid client certificate (Second NATS) */
  @Test
  public void verifyNatsForMTLSSecondNATS() throws Exception {
    LOG.info("Running verifyNatsForMTLSSecondNATS test");
    SSLContext sslContext =
        createSSLContext(
            new ByteArrayInputStream(CLIENT_KEYSTORE_BYTES),
            new ByteArrayInputStream(CA_CERT_BYTES),
            true);
    try {
      Client client = new Client(new URI(WSS_URI_SECOND_NATS));
      SSLSocketFactory factory = sslContext.getSocketFactory();
      client.setSocketFactory(factory);
      client.connectBlocking();
      client.send("Hello Second NATS!");
      LOG.info("message sent");
    } catch (URISyntaxException | InterruptedException e) {
      throw new QAException("Not able to connect to Second NATs", e);
    }
  }

  /**
   * Verify ECE endpoints can connect with TLS with a valid server certificate
   *
   * <p><a>
   * href=https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=1&id=3991843>TC-5161</a>
   */
  @Test
  public void verifyEceEndpointsTLS() throws Exception {
    LOG.info("Running verifyEceEndpointsTLS test");
    for (String eceEndpoint : TLS_ECE_ENDPOINTS) {
      LOG.info("Verify Ece only endpoint TLS: " + "https://" + host_ip + eceEndpoint);
      assertThat(
              callEndpoint(
                  createHttpClient(null, new ByteArrayInputStream(TLS_CA_CERT_BYTES), true),
                  "https://" + host_ip + eceEndpoint))
          .isNotIn(503, 525);
    }
  }

  /**
   * Verify ECE endpoints with mTLS with invalid cert are not able to connect
   *
   * <p><a>
   * href=https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=1&id=3991844>TC-5162</a>
   */
  @Test
  public void verifyEceOnlyEndpointMTLSInvalidCert() {
    LOG.info("Running verifyEceOnlyEndpointMTLSInvalidCert test");
    for (String eceEndpoint : mTLS_ECE_ENDPOINTS) {
      try {
        LOG.info("Verify Ece only endpoint mTLS: {}{}", HOST_mTLS_DELL, eceEndpoint);
        callEndpoint(
            createHttpClient(
                new ByteArrayInputStream(CLIENT_KEYSTORE_INV_BYTES),
                new ByteArrayInputStream(CLIENT_CERT_BYTES),
                true),
            HOST_mTLS_DELL + eceEndpoint);
      } catch (Exception e) {
        LOG.info("Got error as expected: {}", e.getMessage());
        assertThat(e.getMessage()).contains(ERROR_MISSING_CERTIFICATE);
      }
    }
  }

  /**
   * Verify connecting to ECE endpoints with TLS without CA cert fails
   *
   * <p><a>
   * href=https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=1&id=3991845>TC-5163</a>
   */
  @Test
  public void verifyEceEndpointTLSWithoutCert() {
    LOG.info("Running verifyEceEndpointTLSWithoutCert test");
    for (String eceEndpoint : TLS_ECE_ENDPOINTS) {
      try {
        LOG.info("Verify Ece only endpoint: {}{}", host_ip, eceEndpoint);
        callEndpoint(
            createHttpClient(null, new ByteArrayInputStream(CA_CERT_BYTES), false),
            HOST_DEFAULT_DELL + eceEndpoint);
      } catch (Exception e) {
        assertThat(e.getMessage()).contains(ERROR_MISSING_CERTIFICATE);
      }
    }
  }

  /**
   * Verify connecting to ECE-only endpoint with mTLS using no client certificate fails
   *
   * <p><a>
   * href=https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=1&id=3991846>TC-5164</a>
   */
  @Test
  public void verifyEceOnlyEndpointMTLSWithoutCert() {
    LOG.info("Running verifyEceOnlyEndpointMTLSWithoutCert test");
    for (String eceOnlyEndpoint : mTLS_ECE_ENDPOINTS) {
      LOG.info("Verify ece only endpoint: {}{}", HOST_mTLS_DELL, eceOnlyEndpoint);
      try {
        callEndpoint(
            createHttpClient(
                new ByteArrayInputStream(CLIENT_KEYSTORE_BYTES),
                new ByteArrayInputStream(CA_CERT_BYTES),
                false),
            HOST_mTLS_DELL + eceOnlyEndpoint);
      } catch (Exception e) {
        assertThat(e.getMessage()).contains(ERROR_MISSING_CERTIFICATE);
      }
    }
  }

  /**
   * Verify non-ECE endpoints can connect with TLS with a valid server certificate
   *
   * <p><a>
   * href=https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=1&id=3991847>TC-5165</a>
   */
  @Test
  public void verifyNonEceOnlyEndpointsTls() throws Exception {
    LOG.info("Running verifyNonEceOnlyEndpointsTls test");
    for (String nonEceEndpoint : TLS_NON_ECE_ENDPOINTS) {
      LOG.info("Verify non-ece only endpoint TLS: {}{}", host_ip, nonEceEndpoint);
      assertThat(
              callEndpoint(
                  createHttpClient(null, new ByteArrayInputStream(TLS_CA_CERT_BYTES), true),
                  "https://" + host_ip + nonEceEndpoint))
          .isNotIn(503, 525);
    }
    for (String host : HOSTS_FDO_RV) {
      LOG.info("Verify non-ece only endpoint TLS: " + host + TLS_FDO_RV_NON_ECE_ENDPOINT);
      assertThat(
              callEndpoint(
                  createHttpClient(null, new ByteArrayInputStream(TLS_CA_CERT_BYTES), true),
                  host + TLS_FDO_RV_NON_ECE_ENDPOINT))
          .isNotIn(503, 525);
    }
  }

  /**
   * Verify connecting to a non-ECE endpoint with TLS without CA cert fails
   *
   * <p><a>
   * href=https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=1&id=3991848>TC-5166</a>
   */
  @Test
  public void verifyNonEceOnlyEndpointTlsWithoutCert() {
    LOG.info("Running verifyNonEceOnlyEndpointTlsWithoutCert test");
    for (String nonEceEndpoint : TLS_NON_ECE_ENDPOINTS) {
      try {
        LOG.info("Verify non-ece only endpoint: {}{}", host_ip, nonEceEndpoint);
        callEndpoint(
            createHttpClient(null, new ByteArrayInputStream(CA_CERT_BYTES), false),
            "https://" + host_ip + nonEceEndpoint);
      } catch (Exception e) {
        assertThat(e.getMessage()).contains(ERROR_MISSING_CERTIFICATE);
      }
    }
    for (String host : HOSTS_FDO_RV) {
      try {
        LOG.info("Verify non-ece only endpoint: {}{}", host, TLS_FDO_RV_NON_ECE_ENDPOINT);
        callEndpoint(
            createHttpClient(null, new ByteArrayInputStream(CA_CERT_BYTES), false),
            host + TLS_FDO_RV_NON_ECE_ENDPOINT);
      } catch (Exception e) {
        assertThat(e.getMessage()).contains(ERROR_MISSING_CERTIFICATE);
      }
    }
  }

  /**
   * Verify connecting to non-ECE endpoint without TLS fails
   *
   * <p><a>
   * href=https://qtest.gtie.dell.com/p/181/portal/project#tab=testdesign&object=1&id=3991849>TC-5167</a>
   */
  @Test
  public void verifyNonEceEndpointWithoutTls() {
    LOG.info("Running verifyNonEceEndpointWithoutTls test");
    for (String nonEceEndpoint : TLS_NON_ECE_ENDPOINTS) {
      try {
        LOG.info(
            "Verify non-ece only endpoint: {}{}", HOST_DEFAULT_DELL_WITHOUT_HTTPS, nonEceEndpoint);
        callEndpoint(
            createHttpClient(null, new ByteArrayInputStream(CA_CERT_BYTES), false),
            HOST_DEFAULT_DELL_WITHOUT_HTTPS + nonEceEndpoint);
      } catch (Exception e) {
        assertThat(e.getMessage()).contains(ERROR_CONNECTION_REFUSED);
      }
    }
  }

  /**
   * This method calls the endpoint
   *
   * @param httpClient
   * @param endPointUrl
   * @return status code
   * @throws IOException
   */
  private int callEndpoint(CloseableHttpClient httpClient, String endPointUrl) throws IOException {
    LOG.info("Verifying endpoint");
    HttpPost httpPost = new HttpPost(endPointUrl);
    httpPost.setHeader("Content-Type", "application/json");
    HttpResponse response = httpClient.execute(httpPost);
    return response.getStatusLine().getStatusCode();
  }

  /**
   * This method creates the CloseableHttpClient
   *
   * @param keyStoreFilename Keystore filename. used for MTLS connections
   * @param withCert if set to true, the cacert will be included in the request
   * @return
   * @throws Exception
   */
  private CloseableHttpClient createHttpClient(
      InputStream keyStoreFilename, InputStream clientCert, Boolean withCert) throws Exception {
    SSLConnectionSocketFactory sslConnectionSocketFactory =
        new SSLConnectionSocketFactory(
            createSSLContext(keyStoreFilename, clientCert, withCert),
            new String[] {PROTOCOL},
            CIPHER_SUITES,
            SSLConnectionSocketFactory.getDefaultHostnameVerifier());

    return HttpClients.custom().setSSLSocketFactory(sslConnectionSocketFactory).build();
  }

  /**
   * Create ssl context
   *
   * @param keyStoreInputStream
   * @param caCertInputStream
   * @param withCert
   * @return
   * @throws QAException
   */
  private SSLContext createSSLContext(
      InputStream keyStoreInputStream, InputStream caCertInputStream, boolean withCert)
      throws CertificateException, KeyStoreException, IOException, NoSuchAlgorithmException {
    LOG.info("Creating SSL Context");
    try {
      KeyStore keyStore = createKeyStore(keyStoreInputStream, caCertInputStream);

      // Create keymanager and load the keystore
      KeyManagerFactory keyManagerFactory =
          KeyManagerFactory.getInstance(KeyManagerFactory.getDefaultAlgorithm());
      char[] keyPass = keyStoreInputStream == null ? "".toCharArray() : KEYPASS_AND_STOREPASS_VALUE;
      keyManagerFactory.init(keyStore, keyPass);

      // Create the trustmanager and load the keystore
      TrustManagerFactory trustManagerFactory = null;
      if (withCert) {
        trustManagerFactory =
            TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        trustManagerFactory.init(keyStore);
      }

      // Create the SSLContext
      SSLContext sslContext = SSLContext.getInstance(PROTOCOL);
      sslContext.init(
          keyManagerFactory.getKeyManagers(),
          trustManagerFactory == null ? null : trustManagerFactory.getTrustManagers(),
          null);
      return sslContext;
    } catch (UnrecoverableKeyException e) {
      throw new RuntimeException(e);
    } catch (KeyManagementException e) {
      throw new RuntimeException(e);
    }
  }

  private KeyStore createKeyStore(InputStream keyStoreInputStream, InputStream caCertInputStream)
      throws CertificateException, KeyStoreException, IOException, NoSuchAlgorithmException {
    LOG.info("Creating keystore");
    CertificateFactory cf = CertificateFactory.getInstance(X509);
    X509Certificate caCrt = (X509Certificate) cf.generateCertificate(caCertInputStream);

    KeyStore keyStore = KeyStore.getInstance(KeyStore.getDefaultType());
    if (keyStoreInputStream == null) {
      keyStore.load(null);
    } else {
      keyStore.load(keyStoreInputStream, KEYPASS_AND_STOREPASS_VALUE);
    }
    keyStore.setCertificateEntry("cacert", caCrt);

    return keyStore;
  }

  /**
   * Fetch the kubernetes cluster ip
   *
   * @return String
   */
  @Test
  public static String getKubernetesClusterIP() {
    String host_name =
        "kubectl cluster-info | grep -oE \'([0-9]{1,3}\\.){3}[0-9]{1,3}\' | awk '{print $1; exit}'";
    return runCommandOnEO(host_name);
  }

  /**
   * Run the command on EO. It assumes the tests are running on the EO itself.
   *
   * @param command String
   * @return String
   */
  public static String runCommandOnEO(String command) {
    String[] cmd = {"/bin/sh", "-c", command};
    String response = "";
    try {
      Process process = Runtime.getRuntime().exec(cmd);
      InputStreamReader in = new InputStreamReader(process.getInputStream());
      BufferedReader buf = new BufferedReader(in);
      String line;
      while ((line = buf.readLine()) != null) {
        response += line;
      }
      int exitVal = process.waitFor();
      LOG.debug("command \"{}\" returned {}", command, exitVal);
      buf.close();
      in.close();
    } catch (Exception e) {
      e.printStackTrace();
    }
    return response;
  }
}

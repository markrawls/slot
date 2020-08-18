(import os)
(import [glob [glob]])
(import [shutil [move]])

(import [use-dir [use-dir]])
(import [box [Box]])

(import [.constants [STORES-DIR]])
(import [.config [Config]])
(import [.exceptions [NotRegisteredError InvalidOptionError]])

(defclass Store []
  (defn --init-- [self name]
    (setv self.name name)
    (setv self.path (os.path.join STORES-DIR name))

    (setv config (Config))
    (if (in name (.keys config.stores))
        (setv self.target (. config stores [name] target))))

  (with-decorator
    property
    (defn options [self]
      (with [(use-dir self.path)]
        (glob "*"))))

  (with-decorator
    property
    (defn registered [self] (and self.exists (os.path.exists self.target) (os.path.islink self.target))))

  (with-decorator
    property
    (defn exists [self] (and (os.path.exists self.path) (in self.name (.stores.keys (Config))))))

  (with-decorator
    property
    (defn selected-option [self]
      (os.path.basename (os.readlink self.target))))

  (defn select [self option]
    (unless self.registered
      (raise (NotRegisteredError (.format "{} is not registered" self.name))))

    (unless (in option self.options)
      (raise (InvalidOptionError)))

    (.unlink os self.target)
    (.symlink
      os
      (os.path.join self.path option)
      self.target))

  (defn ingest [self new-name &optional file-name link]
    (setv target self.target)

    (if (not (none? file-name)) (setv target file-name))

    (setv new-path (os.path.join self.path new-name))
    (move target new-path)

    (if link (.symlink os new-path self.target)))

  (defn create [self target]
    (setv config (Config))

    (.makedirs os self.path :exist-ok True)
    (assoc config.stores self.name (Box {}))
    (assoc (. config stores [self.name]) "target" target)

    (setv self.target target)

    (.dump Config config)))

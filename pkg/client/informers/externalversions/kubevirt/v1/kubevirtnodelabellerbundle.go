/*
Copyright The Kubernetes Authors.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

// Code generated by informer-gen. DO NOT EDIT.

package v1

import (
	time "time"

	kubevirtv1 "github.com/kubevirt/kubevirt-ssp-operator/pkg/apis/kubevirt/v1"
	versioned "github.com/kubevirt/kubevirt-ssp-operator/pkg/client/clientset/versioned"
	internalinterfaces "github.com/kubevirt/kubevirt-ssp-operator/pkg/client/informers/externalversions/internalinterfaces"
	v1 "github.com/kubevirt/kubevirt-ssp-operator/pkg/client/listers/kubevirt/v1"
	metav1 "k8s.io/apimachinery/pkg/apis/meta/v1"
	runtime "k8s.io/apimachinery/pkg/runtime"
	watch "k8s.io/apimachinery/pkg/watch"
	cache "k8s.io/client-go/tools/cache"
)

// KubevirtNodeLabellerBundleInformer provides access to a shared informer and lister for
// KubevirtNodeLabellerBundles.
type KubevirtNodeLabellerBundleInformer interface {
	Informer() cache.SharedIndexInformer
	Lister() v1.KubevirtNodeLabellerBundleLister
}

type kubevirtNodeLabellerBundleInformer struct {
	factory          internalinterfaces.SharedInformerFactory
	tweakListOptions internalinterfaces.TweakListOptionsFunc
	namespace        string
}

// NewKubevirtNodeLabellerBundleInformer constructs a new informer for KubevirtNodeLabellerBundle type.
// Always prefer using an informer factory to get a shared informer instead of getting an independent
// one. This reduces memory footprint and number of connections to the server.
func NewKubevirtNodeLabellerBundleInformer(client versioned.Interface, namespace string, resyncPeriod time.Duration, indexers cache.Indexers) cache.SharedIndexInformer {
	return NewFilteredKubevirtNodeLabellerBundleInformer(client, namespace, resyncPeriod, indexers, nil)
}

// NewFilteredKubevirtNodeLabellerBundleInformer constructs a new informer for KubevirtNodeLabellerBundle type.
// Always prefer using an informer factory to get a shared informer instead of getting an independent
// one. This reduces memory footprint and number of connections to the server.
func NewFilteredKubevirtNodeLabellerBundleInformer(client versioned.Interface, namespace string, resyncPeriod time.Duration, indexers cache.Indexers, tweakListOptions internalinterfaces.TweakListOptionsFunc) cache.SharedIndexInformer {
	return cache.NewSharedIndexInformer(
		&cache.ListWatch{
			ListFunc: func(options metav1.ListOptions) (runtime.Object, error) {
				if tweakListOptions != nil {
					tweakListOptions(&options)
				}
				return client.KubevirtV1().KubevirtNodeLabellerBundles(namespace).List(options)
			},
			WatchFunc: func(options metav1.ListOptions) (watch.Interface, error) {
				if tweakListOptions != nil {
					tweakListOptions(&options)
				}
				return client.KubevirtV1().KubevirtNodeLabellerBundles(namespace).Watch(options)
			},
		},
		&kubevirtv1.KubevirtNodeLabellerBundle{},
		resyncPeriod,
		indexers,
	)
}

func (f *kubevirtNodeLabellerBundleInformer) defaultInformer(client versioned.Interface, resyncPeriod time.Duration) cache.SharedIndexInformer {
	return NewFilteredKubevirtNodeLabellerBundleInformer(client, f.namespace, resyncPeriod, cache.Indexers{cache.NamespaceIndex: cache.MetaNamespaceIndexFunc}, f.tweakListOptions)
}

func (f *kubevirtNodeLabellerBundleInformer) Informer() cache.SharedIndexInformer {
	return f.factory.InformerFor(&kubevirtv1.KubevirtNodeLabellerBundle{}, f.defaultInformer)
}

func (f *kubevirtNodeLabellerBundleInformer) Lister() v1.KubevirtNodeLabellerBundleLister {
	return v1.NewKubevirtNodeLabellerBundleLister(f.Informer().GetIndexer())
}
